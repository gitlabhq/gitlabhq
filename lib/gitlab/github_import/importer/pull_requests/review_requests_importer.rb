# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module PullRequests
        class ReviewRequestsImporter
          include ParallelScheduling

          BATCH_SIZE = 100

          private

          def each_object_to_import(&block)
            merge_request_collection.each_batch(of: BATCH_SIZE, column: :iid) do |batch|
              batch.each do |merge_request|
                repo = project.import_source

                review_requests = client.pull_request_review_requests(repo, merge_request.iid)
                review_requests[:merge_request_id] = merge_request.id
                review_requests[:merge_request_iid] = merge_request.iid
                yield review_requests

                mark_merge_request_imported(merge_request)
              end
            end
          end

          def importer_class
            ReviewRequestImporter
          end

          def representation_class
            Gitlab::GithubImport::Representation::PullRequests::ReviewRequests
          end

          def sidekiq_worker_class
            Gitlab::GithubImport::PullRequests::ImportReviewRequestWorker
          end

          def collection_method
            :pull_request_review_requests
          end

          # rubocop:disable CodeReuse/ActiveRecord
          def merge_request_collection
            project.merge_requests
              .where.not(iid: already_imported_merge_requests)
              .select(:id, :iid)
          end
          # rubocop:enable CodeReuse/ActiveRecord

          def merge_request_imported_cache_key
            "github-importer/pull_requests/#{collection_method}/already-imported/#{project.id}"
          end

          def already_imported_merge_requests
            Gitlab::Cache::Import::Caching.values_from_set(merge_request_imported_cache_key)
          end

          def mark_merge_request_imported(merge_request)
            Gitlab::Cache::Import::Caching.set_add(
              merge_request_imported_cache_key,
              merge_request.iid
            )
          end
        end
      end
    end
  end
end
