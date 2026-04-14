# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module Stage
      class ImportRepositoryWorker # rubocop:disable Scalability/IdempotentWorker
        include StageMethods

        private

        def import(project)
          # If a user creates a merge request or issue while the import is in progress,
          # this can lead to an import failure due to IID conflicts.
          # Pre-allocating IIDs prevents this race condition.
          preallocate_iids!(project)

          importer = importer_class.new(project)

          importer.execute

          ImportUsersWorker.perform_async(project.id)
        end

        def preallocate_iids!(project)
          max_iids = {}
          repo = project.import_source
          client = Bitbucket::Client.new(project.import_data.credentials)

          unless iid_allocated?(project, :merge_requests)
            max_pr_iid = client.last_pull_request(repo)&.iid
            max_iids[:merge_requests] = max_pr_iid if Gitlab::Import::IidPreallocator.valid_iid_value?(max_pr_iid)
          end

          unless iid_allocated?(project, :issues)
            max_issue_iid = client.last_issue(repo)&.iid
            max_iids[:issues] = max_issue_iid if Gitlab::Import::IidPreallocator.valid_iid_value?(max_issue_iid)
          end

          return if max_iids.empty?

          Gitlab::Import::IidPreallocator.new(project, max_iids).execute
        end

        def iid_allocated?(project, usage)
          InternalId.exists?(project: project, usage: usage) # rubocop:disable CodeReuse/ActiveRecord -- lightweight existence check
        end

        def importer_class
          Importers::RepositoryImporter
        end
      end
    end
  end
end
