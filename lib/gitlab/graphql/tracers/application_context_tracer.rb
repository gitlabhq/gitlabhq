# frozen_string_literal: true

module Gitlab
  module Graphql
    module Tracers
      # This graphql-ruby tracer sets up `ApplicationContext` for certain operations.
      module ApplicationContextTracer
        def execute_query(query:)
          operation = known_operation(query)

          ::Gitlab::ApplicationContext.with_context(caller_id: operation.to_caller_id) do
            super
          end
        end

        private

        def known_operation(query)
          ::Gitlab::Graphql::KnownOperations.default.from_query(query)
        end
      end
    end
  end
end
