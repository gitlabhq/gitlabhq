# frozen_string_literal: true

module Gitlab
  module ErrorTracking
    class Logger < ::Gitlab::JsonLogger
      def self.capture_exception(exception, **context_payload)
        formatter = Gitlab::ErrorTracking::LogFormatter.new
        log_hash = formatter.generate_log(exception, context_payload)

        self.error(log_hash)
      end

      def self.file_name_noext
        'exceptions_json'
      end
    end
  end
end
