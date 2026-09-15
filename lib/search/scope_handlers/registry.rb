# frozen_string_literal: true

module Search
  module ScopeHandlers
    class Registry
      class << self
        def register(scope, handler_class)
          registry[scope.to_s] = handler_class
        end

        def for_scope(scope)
          registry[scope.to_s]
        end

        def registered?(scope)
          registry.key?(scope.to_s)
        end

        def registered_scopes
          registry.keys
        end

        private

        def registry
          @registry ||= {}
        end
      end
    end
  end
end
