# frozen_string_literal: true

module Types
  module Authz
    module PersonalAccessTokens
      # rubocop:disable Graphql/AuthorizeTypes -- Authorization handled in the resolver
      class PersonalAccessTokenType < BaseObject
        graphql_name 'PersonalAccessToken'
        description 'Personal access token.'

        field :id,
          GraphQL::Types::ID,
          null: false,
          description: 'ID of the personal access token.'

        field :name,
          GraphQL::Types::String,
          null: false,
          description: 'Name of the personal access token.'

        field :description,
          GraphQL::Types::String,
          null: true,
          description: 'Description of the personal access token.'

        field :granular,
          GraphQL::Types::Boolean,
          null: false,
          description: 'Whether the personal access token is granular.'

        field :revoked,
          GraphQL::Types::Boolean,
          null: false,
          description: 'Whether the personal access token has been revoked.'

        field :active,
          GraphQL::Types::Boolean,
          null: false,
          description: 'Whether the personal access token is active.',
          method: :active?

        field :scopes,
          [Types::Authz::PersonalAccessTokens::ScopeType],
          null: false,
          description: 'List of scopes applied to a personal access token.'

        field :last_used_at,
          Types::TimeType,
          null: true,
          description: 'Timestamp of when the personal access token was last used.'

        field :created_at,
          Types::TimeType,
          null: false,
          description: 'Timestamp of when the personal access token was created.'

        field :expires_at,
          Types::DateType,
          null: true,
          description: 'Date of when the personal access token expires.'

        def scopes
          object.granular? ? object.granular_scopes : object.scopes
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
