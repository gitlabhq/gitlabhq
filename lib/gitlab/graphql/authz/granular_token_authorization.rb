# frozen_string_literal: true

module Gitlab
  module Graphql
    module Authz
      # Field extension for granular token authorization
      class GranularTokenAuthorization < GraphQL::Schema::FieldExtension
        include ::Gitlab::Graphql::Authorize::AuthorizeResource

        BOUNDARY_TYPE_EVALUATION_ORDER = %w[project group user instance].freeze

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
          permissions = permissions(matching_directive)

          authorize_with_cache!(context, boundary, permissions)
        end

        def authorization_enabled?(context)
          token = context[:access_token]
          token && token.try(:granular?)
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

          boundary_type = directive.arguments[:boundary_type]
          procs = @field.owner.try(:granular_token_boundary_procs) || {}

          BoundaryExtractor.new(
            object: object,
            arguments: arguments,
            context: context,
            directive: directive,
            boundary_proc: procs[boundary_type]
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
