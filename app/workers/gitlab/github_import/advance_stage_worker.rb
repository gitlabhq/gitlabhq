# frozen_string_literal: true

module Gitlab
  module GithubImport
    # AdvanceStageWorker is a worker used by the GitHub importer to wait for a
    # number of jobs to complete, without blocking a thread. Once all jobs have
    # been completed this worker will advance the import process to the next
    # stage.
    class AdvanceStageWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker

      data_consistency :always

      include ::Gitlab::Import::AdvanceStage

      loggable_arguments 1, 2

      # The known importer stages and their corresponding Sidekiq workers.
      #
      # Note: AdvanceStageWorker is not used to initiate the repository, base_data, and pull_requests stages.
      # They are included in the list for us to easily see all stage workers and the order in which they are executed.

      STAGES = {
        repository: Stage::ImportRepositoryWorker,
        base_data: Stage::ImportBaseDataWorker,
        pull_requests: Stage::ImportPullRequestsWorker,
        collaborators: Stage::ImportCollaboratorsWorker,
        issues_and_diff_notes: Stage::ImportIssuesAndDiffNotesWorker,
        issue_events: Stage::ImportIssueEventsWorker,
        attachments: Stage::ImportAttachmentsWorker,
        protected_branches: Stage::ImportProtectedBranchesWorker,
        lfs_objects: Stage::ImportLfsObjectsWorker,
        finish: Stage::FinishImportWorker
      }.freeze

      def find_import_state_jid(project_id)
        ProjectImportState.jid_by(project_id: project_id, status: :started)
      end

      def find_import_state(id)
        ProjectImportState.find(id)
      end

      private

      def proceed_to_next_stage(import_state_jid, next_stage, project_id)
        project = Project.find_by_id(project_id)
        import_settings = Gitlab::GithubImport::Settings.new(project)

        load_references(project) if import_settings.user_mapping_enabled?

        super
      end

      def next_stage_worker(next_stage)
        STAGES.fetch(next_stage.to_sym)
      end

      def load_references(project)
        ::Import::LoadPlaceholderReferencesWorker.perform_async(
          ::Import::SOURCE_GITHUB,
          project.import_state.id,
          { 'current_user_id' => project.creator_id })
      end
    end
  end
end
