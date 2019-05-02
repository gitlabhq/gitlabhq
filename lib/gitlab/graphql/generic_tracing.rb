# frozen_string_literal: true

# This class is used as a hook to observe graphql runtime events. From this
# hook both gitlab metrics and opentracking measurements are generated

module Gitlab
  module Graphql
    class GenericTracing < GraphQL::Tracing::PlatformTracing
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
        tags = { platform_key: platform_key, key: key }
        start = Gitlab::Metrics::System.monotonic_time

        with_labkit_tracing(tags, &block)
      ensure
        duration = Gitlab::Metrics::System.monotonic_time - start

        graphql_duration_seconds.observe(tags, duration)
      end

      private

      def with_labkit_tracing(tags, &block)
        return yield unless Labkit::Tracing.enabled?

        name = "#{tags[:platform_key]}.#{tags[:key]}"
        span_tags = {
          'component' => 'web',
          'span.kind' => 'server'
        }.merge(tags.stringify_keys)

        Labkit::Tracing.with_tracing(operation_name: name, tags: span_tags, &block)
      end

      def graphql_duration_seconds
        @graphql_duration_seconds ||= Gitlab::Metrics.histogram(
          :graphql_duration_seconds,
          'GraphQL execution time'
        )
      end
    end
  end
end
