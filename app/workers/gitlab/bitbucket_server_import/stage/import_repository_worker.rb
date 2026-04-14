# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Stage
      class ImportRepositoryWorker # rubocop:disable Scalability/IdempotentWorker
        include StageMethods

        private

        # project - An instance of Project.
        def import(project)
          # If a user creates a merge request while the import is in progress,
          # this can lead to an import failure due to IID conflicts.
          # Pre-allocating IIDs prevents this race condition.
          preallocate_iids!(project)

          importer = importer_class.new(project)

          importer.execute

          ImportPullRequestsWorker.perform_async(project.id)
        end

        def preallocate_iids!(project)
          max_iids = {}

          unless iid_allocated?(project, :merge_requests)
            max_pr_iid = fetch_max_pull_request_iid(project)
            max_iids[:merge_requests] = max_pr_iid if Gitlab::Import::IidPreallocator.valid_iid_value?(max_pr_iid)
          end

          return if max_iids.empty?

          Gitlab::Import::IidPreallocator.new(project, max_iids).execute
        end

        def iid_allocated?(project, usage)
          InternalId.exists?(project: project, usage: usage) # rubocop: disable CodeReuse/ActiveRecord -- lightweight existence check
        end

        def fetch_max_pull_request_iid(project)
          import_data = project.import_data
          client = BitbucketServer::Client.new(import_data.credentials)
          project_key = import_data.data['project_key']
          repository_slug = import_data.data['repo_slug']

          last_pull_request = client.last_pull_request(project_key, repository_slug)
          last_pull_request&.iid
        end

        def importer_class
          Importers::RepositoryImporter
        end
      end
    end
  end
end
