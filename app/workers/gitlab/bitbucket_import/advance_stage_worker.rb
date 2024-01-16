# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    # AdvanceStageWorker is a worker used by the BitBucket Importer to wait for a
    # number of jobs to complete, without blocking a thread. Once all jobs have
    # been completed this worker will advance the import process to the next
    # stage.
    class AdvanceStageWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker
      include ::Gitlab::Import::AdvanceStage

      data_consistency :delayed

      loggable_arguments 1, 2

      # The known importer stages and their corresponding Sidekiq workers.
      STAGES = {
        repository: Stage::ImportRepositoryWorker,
        pull_requests: Stage::ImportPullRequestsWorker,
        pull_requests_notes: Stage::ImportPullRequestsNotesWorker,
        issues: Stage::ImportIssuesWorker,
        issues_notes: Stage::ImportIssuesNotesWorker,
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

      def next_stage_worker(next_stage)
        STAGES.fetch(next_stage.to_sym)
      end
    end
  end
end
