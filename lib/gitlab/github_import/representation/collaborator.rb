# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Representation
      class Collaborator
        include Representable

        expose_attribute :id, :login, :role_name

        # Builds a user from a GitHub API response.
        #
        # collaborator - An instance of `Hash` containing the user & role details.
        def self.from_api_response(collaborator, _additional_data = {})
          new(
            id: collaborator[:id],
            login: collaborator[:login],
            role_name: collaborator[:role_name]
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

        def github_identifiers
          {
            id: id,
            login: login
          }
        end
      end
    end
  end
end
