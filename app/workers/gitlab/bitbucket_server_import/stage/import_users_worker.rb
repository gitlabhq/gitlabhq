# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Stage
      class ImportUsersWorker # rubocop:disable Scalability/IdempotentWorker -- ImportPullRequestsWorker is not idempotent
        include StageMethods

        private

        def import(project)
          importer = importer_class.new(project)

          importer.execute

          ImportPullRequestsWorker.perform_async(project.id)
        end

        def importer_class
          Importers::UsersImporter
        end
      end
    end
  end
end
