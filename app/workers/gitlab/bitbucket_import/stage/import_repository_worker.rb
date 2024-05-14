# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module Stage
      class ImportRepositoryWorker # rubocop:disable Scalability/IdempotentWorker
        include StageMethods

        private

        def import(project)
          importer = importer_class.new(project)

          importer.execute

          if Feature.enabled?(:bitbucket_cloud_convert_mentions_to_users, project.creator)
            return ImportUsersWorker.perform_async(project.id)
          end

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
