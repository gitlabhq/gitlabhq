# frozen_string_literal: true

module Types
  module Authz
    module PersonalAccessTokens
      class ScopeType < BaseUnion
        graphql_name 'PersonalAccessTokenScope'
        description 'Scope applied to a personal access token.'

        possible_types Types::Authz::AccessTokens::LegacyScopeType, Types::Authz::AccessTokens::GranularScopeType

        def self.resolve_type(object, _context)
          case object
          when ::Authz::GranularScope
            Types::Authz::AccessTokens::GranularScopeType
          when String
            Types::Authz::AccessTokens::LegacyScopeType
          else
            raise ::Gitlab::Graphql::Errors::BaseError, "Unknown scope type #{object.class.name}"
          end
        end
      end
    end
  end
end
