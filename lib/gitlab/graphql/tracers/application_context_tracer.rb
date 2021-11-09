# frozen_string_literal: true

module Gitlab
  module Graphql
    module Tracers
      # This graphql-ruby tracer sets up `ApplicationContext` for certain operations.
      class ApplicationContextTracer
        def self.use(schema)
          schema.tracer(self.new)
        end

        # See docs on expected interface for trace
        # https://graphql-ruby.org/api-doc/1.12.17/GraphQL/Tracing
        def trace(key, data)
          case key
          when "execute_query"
            operation = known_operation(data)

            ::Gitlab::ApplicationContext.with_context(caller_id: operation.to_caller_id) do
              yield
            end
          else
            yield
          end
        end

        private

        def known_operation(data)
          # The library guarantees that we should have :query for execute_query, but we're being defensive here
          query = data.fetch(:query, nil)

          return ::Gitlab::Graphql::KnownOperations.UNKNOWN unless query

          ::Gitlab::Graphql::KnownOperations.default.from_query(query)
        end
      end
    end
  end
end
