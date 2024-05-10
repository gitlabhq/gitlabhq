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

          if Feature.enabled?(:bitbucket_server_convert_mentions_to_users, project.creator)
            ImportUsersWorker.perform_async(project.id)
          else
            ImportPullRequestsWorker.perform_async(project.id)
          end
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
