# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Representation
      class ProtectedBranch
        include ToHash
        include ExposeAttribute

        attr_reader :attributes

        expose_attribute :id, :allow_force_pushes, :required_conversation_resolution, :required_signatures,
                         :required_pull_request_reviews, :require_code_owner_reviews

        # Builds a Branch Protection info from a GitHub API response.
        # Resource structure details:
        # https://docs.github.com/en/rest/branches/branch-protection#get-branch-protection
        # branch_protection - An instance of `Hash` containing the protection details.
        def self.from_api_response(branch_protection, _additional_object_data = {})
          branch_name = branch_protection[:url].match(%r{/branches/(\S{1,255})/protection$})[1]

          hash = {
            id: branch_name,
            allow_force_pushes: branch_protection.dig(:allow_force_pushes, :enabled),
            required_conversation_resolution: branch_protection.dig(:required_conversation_resolution, :enabled),
            required_signatures: branch_protection.dig(:required_signatures, :enabled),
            required_pull_request_reviews: branch_protection[:required_pull_request_reviews].present?,
            require_code_owner_reviews: branch_protection.dig(:required_pull_request_reviews,
                                                              :require_code_owner_reviews).present?
          }

          new(hash)
        end

        # Builds a new Protection using a Hash that was built from a JSON payload.
        def self.from_json_hash(raw_hash)
          new(Representation.symbolize_hash(raw_hash))
        end

        # attributes - A Hash containing the raw Protection details. The keys of this
        #              Hash (and any nested hashes) must be symbols.
        def initialize(attributes)
          @attributes = attributes
        end

        def github_identifiers
          { id: id }
        end
      end
    end
  end
end
