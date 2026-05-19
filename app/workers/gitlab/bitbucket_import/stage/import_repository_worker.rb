# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module Stage
      class ImportRepositoryWorker # rubocop:disable Scalability/IdempotentWorker
        include StageMethods

        MAX_IID_CACHE_KEY = 'bitbucket-importer/max-iid/%{project_id}/%{usage}'

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
            max_pr_iid = fetch_last_iid('pull request', project) { client.last_pull_request(repo) }
            if Gitlab::Import::IidPreallocator.valid_iid_value?(max_pr_iid)
              max_iids[:merge_requests] = max_pr_iid
              cache_max_iid(project, :merge_requests, max_pr_iid)
            end
          end

          unless iid_allocated?(project, :issues)
            max_issue_iid = fetch_last_iid('issue', project) { client.last_issue(repo) }
            if Gitlab::Import::IidPreallocator.valid_iid_value?(max_issue_iid)
              max_iids[:issues] = max_issue_iid
              cache_max_iid(project, :issues, max_issue_iid)
            end
          end

          return if max_iids.empty?

          Gitlab::Import::IidPreallocator.new(project, max_iids).execute
        end

        def fetch_last_iid(resource_type, project)
          yield&.iid
        rescue OAuth2::Error => e
          http_status = e.response.try(:status)

          log_iid_fetch_error(resource_type, project,
            http_status_code: http_status,
            error: bitbucket_error_message(e, http_status)
          )

          nil
        rescue Bitbucket::ExponentialBackoff::RateLimitError => e
          log_iid_fetch_error(resource_type, project, error: e.message)

          nil
        end

        def log_iid_fetch_error(resource_type, project, **extra)
          Logger.warn(
            log_attributes(
              project.id,
              extra.compact.merge(message: "Failed to fetch last #{resource_type} IID for pre-allocation")
            )
          )
        end

        def cache_max_iid(project, usage, max_iid)
          cache_key = format(MAX_IID_CACHE_KEY, project_id: project.id, usage: usage)
          Gitlab::Cache::Import::Caching.write(cache_key, max_iid,
            timeout: Gitlab::Cache::Import::Caching::LONGER_TIMEOUT)
        end

        def iid_allocated?(project, usage)
          InternalId.exists?(project: project, usage: usage) # rubocop:disable CodeReuse/ActiveRecord -- lightweight existence check
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
