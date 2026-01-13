# frozen_string_literal: true

module Gitlab
  module Graphql
    module Authz
      module AuthorizeGranularToken
        extend ActiveSupport::Concern

        class_methods do
          # Returns a hash suitable for the directives: parameter in field definitions
          def granular_scope_directive(permissions:, boundary: nil, boundary_argument: nil)
            {
              Directives::Authz::GranularScope => granular_scope_arguments(
                permissions: permissions,
                boundary: boundary,
                boundary_argument: boundary_argument
              )
            }
          end

          # Applies the GranularScope directive to a type or mutation class
          def authorize_granular_token(permissions:, boundary: nil, boundary_argument: nil)
            directive Directives::Authz::GranularScope,
              **granular_scope_arguments(
                permissions: permissions,
                boundary: boundary,
                boundary_argument: boundary_argument
              )
          end

          private

          def granular_scope_arguments(permissions:, boundary:, boundary_argument:)
            {
              permissions: Array.wrap(permissions).map(&:to_s).map(&:upcase),
              boundary: boundary&.to_s,
              boundary_argument: boundary_argument&.to_s
            }.compact
          end
        end
      end
    end
  end
end
