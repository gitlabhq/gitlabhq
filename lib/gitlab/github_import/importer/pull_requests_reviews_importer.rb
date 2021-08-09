# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class PullRequestsReviewsImporter
        include ParallelScheduling

        def initialize(...)
          super

          @merge_requests_already_imported_cache_key =
            "github-importer/merge_request/already-imported/#{project.id}"
        end

        def importer_class
          PullRequestReviewImporter
        end

        def representation_class
          Gitlab::GithubImport::Representation::PullRequestReview
        end

        def sidekiq_worker_class
          ImportPullRequestReviewWorker
        end

        def collection_method
          :pull_request_reviews
        end

        def object_type
          :pull_request_review
        end

        def id_for_already_imported_cache(review)
          review.id
        end

        # The worker can be interrupted, by rate limit for instance,
        # in different situations. To avoid requesting already imported data,
        # if the worker is interrupted:
        # - before importing all reviews of a merge request
        #   The reviews page is cached with the `PageCounter`, by merge request.
        # - before importing all merge requests reviews
        #   Merge requests that had all the reviews imported are cached with
        #   `mark_merge_request_reviews_imported`
        def each_object_to_import(&block)
          each_review_page do |page, merge_request|
            page.objects.each do |review|
              next if already_imported?(review)

              Gitlab::GithubImport::ObjectCounter.increment(project, object_type, :fetched)

              review.merge_request_id = merge_request.id
              yield(review)

              mark_as_imported(review)
            end
          end
        end

        private

        attr_reader :merge_requests_already_imported_cache_key

        def each_review_page
          merge_requests_to_import.find_each do |merge_request|
            # The page counter needs to be scoped by merge request to avoid skipping
            # pages of reviews from already imported merge requests.
            page_counter = PageCounter.new(project, page_counter_id(merge_request))
            repo = project.import_source
            options = collection_options.merge(page: page_counter.current)

            client.each_page(collection_method, repo, merge_request.iid, options) do |page|
              next unless page_counter.set(page.number)

              yield(page, merge_request)
            end

            # Avoid unnecessary Redis cache keys after the work is done.
            page_counter.expire!
            mark_merge_request_reviews_imported(merge_request)
          end
        end

        # Returns only the merge requests that still have reviews to be imported.
        def merge_requests_to_import
          project.merge_requests.where.not(id: already_imported_merge_requests) # rubocop: disable CodeReuse/ActiveRecord
        end

        def already_imported_merge_requests
          Gitlab::Cache::Import::Caching.values_from_set(merge_requests_already_imported_cache_key)
        end

        def page_counter_id(merge_request)
          "merge_request/#{merge_request.id}/#{collection_method}"
        end

        def mark_merge_request_reviews_imported(merge_request)
          Gitlab::Cache::Import::Caching.set_add(
            merge_requests_already_imported_cache_key,
            merge_request.id
          )
        end
      end
    end
  end
end
