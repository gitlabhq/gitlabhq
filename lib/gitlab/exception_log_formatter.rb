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

      if exception.backtrace
        payload['exception.backtrace'] = Rails.backtrace_cleaner.clean(exception.backtrace)
      end
    end
  end
end
