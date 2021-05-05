# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class PullRequestsReviewsImporter
        include ParallelScheduling

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

        def id_for_already_imported_cache(merge_request)
          merge_request.id
        end

        def each_object_to_import
          project.merge_requests.find_each do |merge_request|
            next if already_imported?(merge_request)

            client
              .pull_request_reviews(project.import_source, merge_request.iid)
              .each do |review|
                review.merge_request_id = merge_request.id
                yield(review)
              end

            mark_as_imported(merge_request)
          end
        end
      end
    end
  end
end
