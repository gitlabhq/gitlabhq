# frozen_string_literal: true

module Gitlab
  module Graphql
    module Authz
      # Field extension for granular token authorization
      class GranularTokenAuthorization < GraphQL::Schema::FieldExtension
        include ::Gitlab::Graphql::Authorize::AuthorizeResource

        def resolve(object:, arguments:, context:, **rest)
          authorize_field(object, arguments, context)

          yield(object, arguments, **rest)
        end

        private

        def authorize_field(object, arguments, context)
          return unless authorization_enabled?(context)
          return if SkipRules.new(@field).should_skip?

          directive = DirectiveFinder.new(@field).find(object)
          boundary = boundary(object, arguments, context, directive)
          permissions = permissions(directive)

          authorize_with_cache!(context, boundary, permissions)
        end

        def authorization_enabled?(context)
          token = context[:access_token]
          token && token.try(:granular?) && Feature.enabled?(:granular_personal_access_tokens_for_graphql, token.user)
        end

        def authorize_with_cache!(context, boundary, permissions)
          cache = context[:authz_cache] ||= Set.new
          cache_key = [permissions&.sort, boundary&.class, boundary&.namespace&.id]

          return if cache.include?(cache_key)

          response = ::Authz::Tokens::AuthorizeGranularScopesService.new(
            boundaries: boundary,
            permissions: permissions,
            token: context[:access_token]
          ).execute

          raise_resource_not_available_error!(response.message) if response.error?

          cache.add(cache_key)
        end

        def boundary(object, arguments, context, directive)
          return unless directive

          BoundaryExtractor.new(object:, arguments:, context:, directive:).extract
        end

        def permissions(directive)
          return unless directive

          directive.arguments[:permissions].map(&:downcase)
        end
      end
    end
  end
end
