# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Representation
      class PullRequestReview
        include Representable

        expose_attribute :author, :note, :review_type, :submitted_at, :merge_request_id, :merge_request_iid, :review_id

        # Builds a PullRequestReview from a GitHub API response.
        #
        # review - An instance of `Hash` containing the note details.
        def self.from_api_response(review, additional_data = {})
          user = Representation::User.from_api_response(review[:user]) if review[:user]

          new(
            merge_request_id: review[:merge_request_id],
            merge_request_iid: review[:merge_request_iid],
            author: user,
            note: review[:body],
            review_type: review[:state],
            submitted_at: review[:submitted_at],
            review_id: review[:id]
          )
        end

        # Builds a new note using a Hash that was built from a JSON payload.
        def self.from_json_hash(raw_hash)
          hash = Representation.symbolize_hash(raw_hash)

          hash[:author] &&= Representation::User.from_json_hash(hash[:author])
          hash[:submitted_at] = Time.parse(hash[:submitted_at]).in_time_zone if hash[:submitted_at].present?

          new(hash)
        end

        # attributes - A Hash containing the raw note details. The keys of this
        #              Hash must be Symbols.
        def initialize(attributes)
          @attributes = attributes
        end

        def approval?
          review_type == 'APPROVED'
        end

        def github_identifiers
          {
            merge_request_iid: merge_request_iid,
            review_id: review_id
          }
        end
      end
    end
  end
end
