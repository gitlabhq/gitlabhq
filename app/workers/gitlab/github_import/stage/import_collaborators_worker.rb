# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class ImportCollaboratorsWorker # rubocop:disable Scalability/IdempotentWorker
        include ApplicationWorker

        data_consistency :always

        sidekiq_options retry: 3
        include GithubImport::Queue
        include StageMethods

        # client - An instance of Gitlab::GithubImport::Client.
        # project - An instance of Project.
        def import(client, project)
          info(project.id, message: "starting importer", importer: 'Importer::CollaboratorsImporter')
          waiter = Importer::CollaboratorsImporter
            .new(project, client)
            .execute

          project.import_state.refresh_jid_expiration

          AdvanceStageWorker.perform_async(
            project.id,
            { waiter.key => waiter.jobs_remaining },
            :pull_requests_merged_by
          )
        rescue StandardError => e
          Gitlab::Import::ImportFailureService.track(
            project_id: project.id,
            error_source: self.class.name,
            exception: e,
            fail_import: abort_on_failure,
            metrics: true
          )

          raise(e)
        end

        private

        def abort_on_failure
          true
        end
      end
    end
  end
end
