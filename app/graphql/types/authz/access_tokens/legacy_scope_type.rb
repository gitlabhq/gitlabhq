# frozen_string_literal: true

module Types
  module Authz
    module AccessTokens
      # rubocop:disable Graphql/AuthorizeTypes -- Authorization handled in the resolver
      class LegacyScopeType < BaseObject
        graphql_name 'AccessTokenLegacyScope'
        description 'Legacy scope applied to an access token'

        field :value,
          GraphQL::Types::String,
          null: false,
          description: 'Value of the scope.'

        def value
          object
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
