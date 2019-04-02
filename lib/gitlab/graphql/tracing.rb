# frozen_string_literal: true

module Gitlab
  module Graphql
    class Tracing < GraphQL::Tracing::PlatformTracing
      self.platform_keys = {
        'lex' => 'graphql.lex',
        'parse' => 'graphql.parse',
        'validate' => 'graphql.validate',
        'analyze_query' => 'graphql.analyze',
        'analyze_multiplex' => 'graphql.analyze',
        'execute_multiplex' => 'graphql.execute',
        'execute_query' => 'graphql.execute',
        'execute_query_lazy' => 'graphql.execute',
        'execute_field' => 'graphql.execute',
        'execute_field_lazy' => 'graphql.execute'
      }

      def platform_field_key(type, field)
        "#{type.name}.#{field.name}"
      end

      def platform_trace(platform_key, key, data, &block)
        start = Gitlab::Metrics::System.monotonic_time

        yield
      ensure
        duration = Gitlab::Metrics::System.monotonic_time - start

        graphql_duration_seconds.observe({ platform_key: platform_key, key: key }, duration)
      end

      private

      def graphql_duration_seconds
        @graphql_duration_seconds ||= Gitlab::Metrics.histogram(
          :graphql_duration_seconds,
          'GraphQL execution time'
        )
      end
    end
  end
end
