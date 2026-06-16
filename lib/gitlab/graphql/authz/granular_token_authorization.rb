# frozen_string_literal: true

module Gitlab
  module Graphql
    module Authz
      # Field extension for granular token authorization
      class GranularTokenAuthorization < GraphQL::Schema::FieldExtension
        include ::Gitlab::Graphql::Authorize::AuthorizeResource

        BOUNDARY_TYPE_EVALUATION_ORDER = %w[project group user instance].freeze
        TRAVERSAL_BOUNDARY_TYPES = %w[project group].freeze

        def resolve(object:, arguments:, context:, **rest)
          authorize_field(object, arguments, context)

          yield(object, arguments, **rest)
        end

        private

        def authorize_field(object, arguments, context)
          return unless authorization_enabled?(context)
          return if SkipRules.new(@field).should_skip?

          directives = DirectiveFinder.new(@field).find_all(object)
          matching_directive = find_matching_directive(directives, object, arguments, context)

          boundary = boundary(object, arguments, context, matching_directive)

          if traversal?(matching_directive)
            authorize_traversal_with_cache!(context, boundary)
          else
            permissions = permissions(matching_directive)
            authorize_with_cache!(context, boundary, permissions)
          end
        end

        def authorization_enabled?(context)
          token = context[:access_token]
          token && token.try(:granular?)
        end

        def authorize_with_cache!(context, boundary, permissions)
          with_authz_cache(context, [permissions&.sort, *boundary_cache_key(boundary)]) do
            response = ::Authz::Tokens::AuthorizeGranularScopesService.new(
              boundaries: boundary,
              permissions: permissions,
              token: context[:access_token]
            ).execute

            raise_resource_not_available_error!(response.message) if response.error?
          end
        end

        def authorize_traversal_with_cache!(context, boundary)
          with_authz_cache(context, [:traversal, *boundary_cache_key(boundary)]) do
            token = context[:access_token]
            not_found = ::Authz::Tokens::AuthorizeGranularScopesService::NOT_FOUND_MESSAGE

            raise_resource_not_available_error!(not_found) unless boundary && token.can?(:read_boundary, boundary)
          end
        end

        def boundary_cache_key(boundary)
          [boundary&.class, boundary&.namespace&.id]
        end

        def with_authz_cache(context, cache_key)
          cache = context[:authz_cache] ||= Set.new
          return if cache.include?(cache_key)

          yield

          cache.add(cache_key)
        end

        # traversal: true only applies to project and group boundaries.
        # All other boundary types fall back to the regular permission check.
        def traversal?(directive)
          return false unless directive
          return false unless directive.arguments[:traversal] == true

          boundary_type = directive.arguments[:boundary_type]&.downcase
          TRAVERSAL_BOUNDARY_TYPES.include?(boundary_type)
        end

        # When multiple directives exist (multi-boundary), select the one whose boundary_type
        # matches the actual extracted boundary. Returns nil if none match, which causes
        # authorize_with_cache! to be called with nil boundary/permissions, denying access.
        def find_matching_directive(directives, object, arguments, context)
          return directives.first if directives.size <= 1

          sorted = directives.sort_by do |d|
            BOUNDARY_TYPE_EVALUATION_ORDER.index(d.arguments[:boundary_type].to_s) ||
              BOUNDARY_TYPE_EVALUATION_ORDER.size
          end

          sorted.each do |d|
            extracted = boundary(object, arguments, context, d)
            next unless extracted

            return d if boundary_matches_type?(extracted, d.arguments[:boundary_type])
          end

          nil
        end

        def boundary_matches_type?(boundary, boundary_type_str)
          return true unless boundary_type_str

          boundary.type_label == boundary_type_str.downcase
        end

        def boundary(object, arguments, context, directive)
          return unless directive

          BoundaryExtractor.new(
            object: object,
            arguments: arguments,
            context: context,
            directive: directive
          ).extract
        end

        def permissions(directive)
          return unless directive

          directive.arguments[:permissions]
        end
      end
    end
  end
end
