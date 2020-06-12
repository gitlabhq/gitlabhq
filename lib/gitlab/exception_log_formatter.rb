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

      payload['extra.sidekiq'].tap do |value|
        if value.is_a?(Hash) && value.key?('args')
          value = value.dup
          payload['extra.sidekiq']['args'] = Gitlab::ErrorTracking::Processor::SidekiqProcessor
                                               .loggable_arguments(value['args'], value['class'])
        end
      end

      if exception.backtrace
        payload['exception.backtrace'] = Gitlab::BacktraceCleaner.clean_backtrace(exception.backtrace)
      end
    end
  end
end
