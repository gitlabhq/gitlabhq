# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module Stage
      class ImportIssuesNotesWorker # rubocop:disable Scalability/IdempotentWorker
        include StageMethods

        private

        # project - An instance of Project.
        def import(project)
          waiter = importer_class.new(project).execute

          project.import_state.refresh_jid_expiration

          AdvanceStageWorker.perform_async(
            project.id,
            { waiter.key => waiter.jobs_remaining },
            :finish
          )
        end

        def importer_class
          Importers::IssuesNotesImporter
        end
      end
    end
  end
end
