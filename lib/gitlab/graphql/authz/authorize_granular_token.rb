# frozen_string_literal: true

module Gitlab
  module Graphql
    module Authz
      module AuthorizeGranularToken
        extend ActiveSupport::Concern

        class_methods do
          # Returns an array of directive hashes suitable for the `directives` parameter in field definitions.
          # Pass `boundaries:` for multi-boundary fields; otherwise a single-element array is returned.
          # `traversal: true` marks an entry-point field: the token is verified to be scoped to the
          # boundary (read_boundary), but the listed permissions are not enforced; downstream fields do.
          def granular_scope_directive(
            permissions:, boundary_type: nil, boundary: nil, boundary_argument: nil,
            boundaries: nil, traversal: nil)
            validate_boundaries!(boundaries) if boundaries

            (boundaries || [{ boundary: boundary, boundary_argument: boundary_argument,
                              boundary_type: boundary_type }]).map do |b|
              {
                Directives::Authz::GranularScope => granular_scope_arguments(
                  permissions: permissions,
                  boundary: b[:boundary],
                  boundary_argument: b[:boundary_argument],
                  boundary_type: b[:boundary_type],
                  traversal: traversal
                )
              }
            end
          end

          # Applies the GranularScope directives to a type or mutation class.
          def authorize_granular_token(
            permissions: nil, boundary_type: nil, boundary: nil, boundary_argument: nil,
            boundaries: nil, traversal: nil, skip_reason: nil)
            other_args = { permissions:, boundary_type:, boundary:, boundary_argument:, boundaries:, traversal: }
            return apply_skip_directive(skip_reason, other_args) if skip_reason

            raise ArgumentError, 'missing keyword: :permissions' if permissions.nil?

            validate_no_traversal!(traversal)
            validate_boundaries!(boundaries) if boundaries

            (boundaries || [{ boundary: boundary, boundary_argument: boundary_argument,
                              boundary_type: boundary_type }]).each do |b|
              directive Directives::Authz::GranularScope,
                **granular_scope_arguments(
                  permissions: permissions,
                  boundary: b[:boundary],
                  boundary_argument: b[:boundary_argument],
                  boundary_type: b[:boundary_type],
                  traversal: traversal
                )
            end
          end

          private

          def apply_skip_directive(reason, other_args)
            validate_skip_authorization!(other_args)

            directive Directives::Authz::GranularScope, skip_reason: reason.to_s
          end

          def validate_skip_authorization!(other_args)
            provided = other_args.select { |_, value| value }.keys
            return if provided.empty?

            raise ArgumentError,
              "`skip_reason:` cannot be combined with: #{provided.map { |k| "#{k}:" }.join(', ')}. " \
                "A type is either authorized directly or intentionally skipped."
          end

          def validate_no_traversal!(traversal)
            return unless traversal

            raise ArgumentError,
              "`traversal:` is not valid on a type-level `authorize_granular_token`. " \
                "Use `granular_scope_directive(traversal: true)` on the field definition instead."
          end

          def validate_boundaries!(boundaries)
            boundaries.each do |b|
              unless b.is_a?(Hash) && b.key?(:boundary_type)
                raise ArgumentError,
                  "Each boundary must be a Hash with at least a :boundary_type key, got: #{b.inspect}"
              end
            end
          end

          def granular_scope_arguments(permissions:, boundary:, boundary_argument:, boundary_type:, traversal: nil)
            {
              permissions: Array.wrap(permissions).map(&:to_s),
              boundary: boundary&.to_s,
              boundary_argument: boundary_argument&.to_s,
              boundary_type: boundary_type&.to_s&.upcase,
              traversal: traversal
            }.compact
          end
        end
      end
    end
  end
end
