# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module Stage
      class ImportPullRequestsWorker # rubocop:disable Scalability/IdempotentWorker
        include StageMethods

        private

        # project - An instance of Project.
        def import(project)
          waiter = importer_class.new(project).execute

          AdvanceStageWorker.perform_async(
            project.id,
            { waiter.key => waiter.jobs_remaining },
            :pull_requests_notes
          )
        end

        def importer_class
          Importers::PullRequestsImporter
        end
      end
    end
  end
end
