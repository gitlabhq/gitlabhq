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
            boundaries: nil)
            validate_boundaries!(boundaries) if boundaries

            (boundaries || [{ boundary: boundary, boundary_argument: boundary_argument,
                              boundary_type: boundary_type }]).map do |b|
              resolved_boundary = register_boundary_proc!(b[:boundary], b[:boundary_type])

              {
                Directives::Authz::GranularScope => granular_scope_arguments(
                  permissions: permissions,
                  boundary: resolved_boundary,
                  boundary_argument: b[:boundary_argument],
                  boundary_type: b[:boundary_type]
                )
              }
            end
          end

          # Applies the GranularScope directives to a type or mutation class.
          # `boundary` may be a Proc for objects where the boundary cannot be derived
          # from a single method call. Procs are stored keyed by boundary_type so
          # multi-boundary types can supply a different proc per boundary.
          def authorize_granular_token(
            permissions:, boundary_type: nil, boundary: nil, boundary_argument: nil,
            boundaries: nil)
            validate_boundaries!(boundaries) if boundaries

            (boundaries || [{ boundary: boundary, boundary_argument: boundary_argument,
                              boundary_type: boundary_type }]).each do |b|
              resolved_boundary = register_boundary_proc!(b[:boundary], b[:boundary_type])

              directive Directives::Authz::GranularScope,
                **granular_scope_arguments(
                  permissions: permissions,
                  boundary: resolved_boundary,
                  boundary_argument: b[:boundary_argument],
                  boundary_type: b[:boundary_type]
                )
            end
          end

          def granular_token_boundary_procs
            ancestors.reverse.each_with_object({}) do |ancestor, hash|
              procs = ancestor.instance_variable_get(:@granular_token_boundary_procs)
              hash.merge!(procs) if procs
            end
          end

          private

          def validate_boundaries!(boundaries)
            boundaries.each do |b|
              unless b.is_a?(Hash) && b.key?(:boundary_type)
                raise ArgumentError,
                  "Each boundary must be a Hash with at least a :boundary_type key, got: #{b.inspect}"
              end
            end
          end

          def register_boundary_proc!(boundary, boundary_type)
            return boundary unless boundary.is_a?(Proc)

            @granular_token_boundary_procs ||= {}
            # Store keyed by the deserialized boundary_type string to match the enum value at resolve time.
            # Return nil so the directive's boundary argument stays unset, since procs are not serializable.
            @granular_token_boundary_procs[boundary_type.to_s] = boundary
            nil
          end

          def granular_scope_arguments(permissions:, boundary:, boundary_argument:, boundary_type:)
            {
              permissions: Array.wrap(permissions).map(&:to_s),
              boundary: boundary&.to_s,
              boundary_argument: boundary_argument&.to_s,
              boundary_type: boundary_type&.to_s&.upcase
            }.compact
          end
        end
      end
    end
  end
end
