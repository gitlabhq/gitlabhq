# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module PullRequests
        class AllMergedByImporter
          include ParallelScheduling

          def importer_class
            MergedByImporter
          end

          def representation_class
            Gitlab::GithubImport::Representation::PullRequest
          end

          def sidekiq_worker_class
            Gitlab::GithubImport::PullRequests::ImportMergedByWorker
          end

          def collection_method
            :pull_requests_merged_by
          end

          def object_type
            :pull_request_merged_by
          end

          def id_for_already_imported_cache(merge_request)
            merge_request.id
          end

          def each_object_to_import
            merge_requests_to_import.find_each do |merge_request|
              Gitlab::GithubImport::ObjectCounter.increment(project, object_type, :fetched)

              pull_request = client.pull_request(project.import_source, merge_request.iid)
              yield(pull_request)

              mark_as_imported(merge_request)
            end
          end

          private

          # Returns only the merge requests that still have merged_by to be imported.
          def merge_requests_to_import
            project.merge_requests.id_not_in(already_imported_objects).with_state(:merged)
          end

          def already_imported_objects
            Gitlab::Cache::Import::Caching.values_from_set(already_imported_cache_key)
          end
        end
      end
    end
  end
end
