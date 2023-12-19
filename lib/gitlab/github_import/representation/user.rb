# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Representation
      class User
        include Representable

        expose_attribute :id, :login

        # Builds a user from a GitHub API response.
        #
        # user - An instance of `Hash` containing the user details.
        def self.from_api_response(user, additional_data = {})
          new(
            id: user[:id],
            login: user[:login]
          )
        end

        # Builds a user using a Hash that was built from a JSON payload.
        def self.from_json_hash(raw_hash)
          new(Representation.symbolize_hash(raw_hash))
        end

        # attributes - A Hash containing the user details. The keys of this
        #              Hash (and any nested hashes) must be symbols.
        def initialize(attributes)
          @attributes = attributes
        end
      end
    end
  end
end
