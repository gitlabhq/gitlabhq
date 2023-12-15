# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Representation
      module PullRequests
        class ReviewRequests
          include Representable

          expose_attribute :merge_request_id, :merge_request_iid, :users

          class << self
            # Builds a list of requested reviewers from a GitHub API response.
            #
            # review_requests - An instance of `Hash` containing the review requests details.
            def from_api_response(review_requests, _additional_data = {})
              review_requests = Representation.symbolize_hash(review_requests)
              users = review_requests[:users].map do |user_data|
                Representation::User.from_api_response(user_data)
              end

              new(
                merge_request_id: review_requests[:merge_request_id],
                merge_request_iid: review_requests[:merge_request_iid],
                users: users
              )
            end
            alias_method :from_json_hash, :from_api_response
          end

          # attributes - A Hash containing the review details. The keys of this
          #              Hash (and any nested hashes) must be symbols.
          def initialize(attributes)
            @attributes = attributes
          end

          def github_identifiers
            {
              merge_request_iid: merge_request_iid,
              requested_reviewers: users.pluck(:login) # rubocop: disable CodeReuse/ActiveRecord
            }
          end
        end
      end
    end
  end
end
