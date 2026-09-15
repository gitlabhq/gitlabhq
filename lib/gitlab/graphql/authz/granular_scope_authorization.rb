# frozen_string_literal: true

module Gitlab
  module Graphql
    module Authz
      class GranularScopeAuthorization
        GRANULAR_TOKENS_AUTHZ_CACHE_KEY = :granular_tokens_authz_cache

        attr_reader :directives

        delegate :empty?, :any?, to: :directives

        def initialize(directives)
          @directives = directives.select { |directive| directive.is_a?(::Directives::Authz::GranularScope) }
        end

        def ok?(object, context, arguments: nil)
          authorized, _message = authorized?(object, context, arguments)
          authorized
        end

        def authorize!(object, context, arguments: nil)
          authorized, message = authorized?(object, context, arguments)
          return if authorized

          raise ::Gitlab::Graphql::Errors::ArgumentError, message
        end

        private

        def skip_authorization?
          directives.any? { |directive| directive.arguments[:skip_reason].present? }
        end

        def permissions_for(group)
          directives
            .find { |directive| directive.arguments[:requirement_group] == group }
            &.arguments&.fetch(:permissions, [])&.sort || []
        end

        def authorized?(object, context, arguments)
          token = context[:access_token]
          return success unless token && token.respond_to?(:granular?)

          # If both object and arguments are nil,
          # there is no source a boundary can be extracted from.
          return success if object.nil? && arguments.nil?
          return success if skip_authorization?

          # if no gPAT directives are defined, granular tokens deny access while
          # legacy tokens fall through to their existing authorization
          if directives.empty?
            return error(default_error_message) if token.granular?

            return success
          end

          boundary_extractor(object, arguments).extract_groups.each do |group, boundary_objects|
            authorized, message = authorize_group(group, boundary_objects, context)

            return error(message) unless authorized
          end

          success
        end

        def authorize_group(group, boundary_objects, context)
          permissions = permissions_for(group)

          fetch_cached(context, cache_key(permissions, boundary_objects)) do
            response = ::Authz::Tokens::AuthorizeGranularScopesService.new(
              boundaries: boundary_objects.map { |resource| ::Authz::Boundary.for(resource) },
              permissions: permissions,
              token: context[:access_token]
            ).execute

            if response.success?
              success
            else
              ::Current.add_granular_denied_permissions(response.payload[:denied_permissions])
              error(response.message)
            end
          end
        end

        def boundary_extractor(object, arguments)
          BoundaryExtractor.new(directives, object: object, arguments: arguments)
        end

        def fetch_cached(context, key)
          cache = context[GRANULAR_TOKENS_AUTHZ_CACHE_KEY] ||= {}
          return cache[key] if cache.key?(key)

          cache[key] = yield
        end

        def cache_key(permissions, boundary_objects)
          [
            permissions,
            boundary_objects.map { |boundary| cache_identifier_for(boundary) }.sort_by(&:to_s)
          ]
        end

        def cache_identifier_for(boundary_object)
          return boundary_object if boundary_object.is_a?(Symbol)

          [boundary_object.class.name, boundary_object.id]
        end

        def success
          [true, nil]
        end

        def error(message)
          [false, message]
        end

        def default_error_message
          ::Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR
        end
      end
    end
  end
end
