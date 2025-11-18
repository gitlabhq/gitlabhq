# frozen_string_literal: true

module Resolvers
  module Users
    class PersonalAccessTokensResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource
      include LooksAhead

      type Types::Authz::PersonalAccessTokens::PersonalAccessTokenType.connection_type, null: true

      authorize :read_user_personal_access_tokens
      authorizes_object!

      alias_method :user, :object

      argument :sort,
        Types::Authz::AccessTokens::SortEnum,
        required: false,
        description: 'Sort personal access tokens by the given criteria. Default is `expires_at_asc`.',
        default_value: 'expires_asc'

      argument :state,
        Types::Authz::AccessTokens::StateEnum,
        required: false,
        description: 'Filter personal access tokens by state. Default is `active`.',
        default_value: 'active'

      argument :revoked,
        GraphQL::Types::Boolean,
        required: false,
        description: 'Filter personal access tokens by their revoked status. Default is `false`.',
        default_value: false

      argument :expires_after, Types::DateType,
        required: false,
        description: 'Filter personal access tokens that expire after the timestamp.'

      argument :created_after, Types::TimeType,
        required: false,
        description: 'Filter personal access tokens created after the timestamp.'

      argument :last_used_after, Types::TimeType,
        required: false,
        description: 'Filter personal access tokens last used after the timestamp.'

      def resolve_with_lookahead(**args)
        personal_access_tokens = PersonalAccessTokensFinder.new({
          user: user,
          state: args[:state],
          sort: args[:sort],
          revoked: args[:revoked],
          expires_after: args[:expires_after],
          created_after: args[:created_after],
          last_used_after: args[:last_used_after]
        }, current_user).execute

        apply_lookahead(personal_access_tokens)
      end

      private

      def preloads
        {
          scopes: {
            granular_scopes: [:namespace]
          }
        }
      end
    end
  end
end
