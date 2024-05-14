# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module Stage
      class ImportUsersWorker
        include StageMethods

        idempotent!

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
