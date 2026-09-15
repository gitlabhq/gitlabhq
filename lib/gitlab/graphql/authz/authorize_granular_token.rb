# frozen_string_literal: true

module Gitlab
  module Graphql
    module Authz
      module AuthorizeGranularToken
        extend ActiveSupport::Concern

        class_methods do
          # Returns an array of directive hashes suitable for the `directives` parameter in field definitions.
          # Pass `boundaries:` for multi-boundary fields; otherwise a single-element array is returned.
          def granular_scope_directive(
            permissions:, boundary_type: nil, boundary: nil, boundary_argument: nil,
            boundaries: nil, additional_scopes: nil, assignable_when: nil)
            validate_boundaries!(boundaries) if boundaries

            requirement_scopes(permissions, boundaries, additional_scopes, assignable_when,
              boundary: boundary, boundary_argument: boundary_argument, boundary_type: boundary_type).map do |b|
              {
                Directives::Authz::GranularScope => granular_scope_arguments(**b)
              }
            end
          end

          # Applies the GranularScope directives to a type or mutation class.
          def authorize_granular_token(
            permissions: nil, boundary_type: nil, boundary: nil, boundary_argument: nil,
            boundaries: nil, skip_reason: nil, additional_scopes: nil, assignable_when: nil)
            other_args = { permissions:, boundary_type:, boundary:, boundary_argument:, boundaries:,
                           additional_scopes:, assignable_when: }
            return apply_skip_directive(skip_reason, other_args) if skip_reason

            raise ArgumentError, 'missing keyword: :permissions' if permissions.nil?

            validate_boundaries!(boundaries) if boundaries

            requirement_scopes(permissions, boundaries, additional_scopes, assignable_when,
              boundary: boundary, boundary_argument: boundary_argument, boundary_type: boundary_type).each do |b|
              directive Directives::Authz::GranularScope, **granular_scope_arguments(**b)
            end
          end

          private

          # The call-level `assignable_when` describes the access gate of the type or
          # mutation itself, so it applies to every scope; a scope hash can add its own.
          def requirement_scopes(permissions, boundaries, additional_scopes, assignable_when, **primary)
            scopes = (boundaries || [primary]).map { |b| b.merge(permissions: permissions) } +
              Array(additional_scopes).each_with_index.map do |b, index|
                b.merge(requirement_group: b[:boundary_argument]&.to_s || "additional_#{index}")
              end

            scopes.map { |b| b.merge(assignable_when: Array.wrap(assignable_when) | Array.wrap(b[:assignable_when])) }
          end

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

          def validate_boundaries!(boundaries)
            boundaries.each do |b|
              unless b.is_a?(Hash) && b.key?(:boundary_type)
                raise ArgumentError,
                  "Each boundary must be a Hash with at least a :boundary_type key, got: #{b.inspect}"
              end
            end
          end

          def granular_scope_arguments(
            permissions:, assignable_when:, boundary: nil, boundary_argument: nil, boundary_type: nil,
            requirement_group: nil)
            {
              permissions: Array.wrap(permissions).map(&:to_s),
              boundary: boundary&.to_s,
              boundary_argument: boundary_argument&.to_s,
              boundary_type: boundary_type&.to_s&.upcase,
              requirement_group: requirement_group,
              assignable_when: assignable_when.map(&:to_s).presence
            }.compact
          end
        end
      end
    end
  end
end
