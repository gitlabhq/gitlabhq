# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Stage
      class ImportRepositoryWorker # rubocop:disable Scalability/IdempotentWorker
        include StageMethods

        private

        # project - An instance of Project.
        def import(project)
          importer = importer_class.new(project)

          importer.execute

          ImportPullRequestsWorker.perform_async(project.id)
        end

        def importer_class
          Importers::RepositoryImporter
        end

        def abort_on_failure
          true
        end
      end
    end
  end
end
