# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module PullRequests
        class ReviewRequestImporter
          def initialize(review_request, project, client)
            @review_request = review_request
            @user_finder = UserFinder.new(project, client)
          end

          def execute
            MergeRequestReviewer.bulk_insert!(build_reviewers)
          end

          private

          attr_reader :review_request, :user_finder

          def build_reviewers
            reviewer_ids = review_request.users.filter_map { |user| user_finder.user_id_for(user) }

            reviewer_ids.map do |reviewer_id|
              MergeRequestReviewer.new(
                merge_request_id: review_request.merge_request_id,
                user_id: reviewer_id,
                state: MergeRequestReviewer.states['unreviewed'],
                created_at: Time.zone.now
              )
            end
          end
        end
      end
    end
  end
end
