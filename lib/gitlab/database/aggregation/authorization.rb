# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      # Part-level authorization for aggregation engines.
      #
      # Part definitions (metrics, dimensions, filters) may declare an
      # `authorize:` option: an ability Symbol checked via `Ability.allowed?`
      # against every resource in `context[:authorization_resources]`, or a
      # callable invoked once with `(user, resources)` that is responsible for
      # authorizing all resources itself. Ability symbols are converted to
      # callables at definition time, so `authorize` is always a callable when
      # present.
      #
      # The engine answers whether a definition is authorized; the query plan
      # applies the answers (see `QueryPlan::Authorization`). Engines without
      # any `authorize:` declarations are not affected.
      module Authorization
        extend ActiveSupport::Concern
        include Gitlab::Utils::StrongMemoize

        # Normalizes the `authorize:` option: an ability Symbol is converted
        # into the equivalent callable, anything else is returned as-is.
        def self.ability_check(authorize)
          return authorize unless authorize.is_a?(Symbol)

          ->(user, resources) { resources.all? { |resource| ::Ability.allowed?(user, authorize, resource) } }
        end

        class_methods do
          def parts_require_authorization?
            (metrics + dimensions + filters).any?(&:authorize)
          end
        end

        # Raises for a misconfigured engine even when the request does not
        # touch a protected part.
        def authorization_required?
          return false unless self.class.parts_require_authorization?

          verify_authorization_context!
          true
        end

        # Memoized per definition: a request builds its query plan more than
        # once (for example, to coerce GraphQL order parameters).
        def authorized_definition?(definition)
          return true unless definition&.authorize

          strong_memoize_with(:authorized_definition, definition) do
            definition.authorize.call(context[:current_user], context[:authorization_resources])
          end
        end

        private

        # `current_user` may be nil: anonymous users can legitimately hold
        # abilities on public resources, so `Ability.allowed?` decides.
        def verify_authorization_context!
          return if context[:authorization_resources].present?

          raise ArgumentError,
            "#{self.class.name} declares part-level authorization: " \
              "`authorization_resources:` is required in the engine context"
        end
      end
    end
  end
end
