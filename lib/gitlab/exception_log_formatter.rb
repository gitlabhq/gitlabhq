# frozen_string_literal: true

module Gitlab
  module ExceptionLogFormatter
    def self.format!(exception, payload)
      return unless exception

      # Elasticsearch/Fluentd don't handle nested structures well.
      # Use periods to flatten the fields.
      payload.merge!(
        'exception.class' => exception.class.name,
        'exception.message' => exception.message
      )

      payload.delete('extra.server')

      # The raven extra context is populated by Raven::SidekiqCleanupMiddleware.
      #
      # It contains the full sidekiq job which consists of mixed types and nested
      # objects. That causes a bunch of issues when trying to ingest logs into
      # Elasticsearch.
      #
      # We apply a stricter schema here that forces the args to be an array of
      # strings. This same logic exists in Gitlab::SidekiqLogging::JSONFormatter.
      payload['extra.sidekiq'].tap do |value|
        if value.is_a?(Hash) && value.key?('args')
          value = value.dup
          payload['extra.sidekiq']['args'] = Gitlab::Utils::LogLimitedArray.log_limited_array(value['args'].try(:map, &:to_s))
        end
      end

      if exception.backtrace
        payload['exception.backtrace'] = Gitlab::BacktraceCleaner.clean_backtrace(exception.backtrace)
      end
    end
  end
end
