# frozen_string_literal: true

# This is backport of https://github.com/rails/rails/pull/26815/files
# Enabled by default for every non-production environment

module ActiveRecord
  class LogSubscriber
    module VerboseQueryLogs
      def debug(progname = nil, &block)
        return unless super

        log_query_source
      end

      def log_query_source
        source_line, line_number = extract_callstack(caller_locations)

        if source_line
          if defined?(::Rails.root)
            app_root = "#{::Rails.root}/".freeze
            source_line = source_line.sub(app_root, "")
          end

          logger.debug("  ↳ #{source_line}:#{line_number}")
        end
      end

      def extract_callstack(callstack)
        line = callstack.find do |frame|
          frame.absolute_path && !ignored_callstack(frame.absolute_path)
        end

        offending_line = line || callstack.first
        [
          offending_line.path,
          offending_line.lineno,
          offending_line.label
        ]
      end

      LOG_SUBSCRIBER_FILE = ActiveRecord::LogSubscriber.method(:logger).source_location.first
      RAILS_GEM_ROOT = File.expand_path("../../../..", LOG_SUBSCRIBER_FILE) + "/"
      APP_CONFIG_ROOT = File.expand_path("..", __dir__) + "/"

      def ignored_callstack(path)
        path.start_with?(APP_CONFIG_ROOT, RAILS_GEM_ROOT, RbConfig::CONFIG["rubylibdir"])
      end
    end

    unless Gitlab.rails5?
      prepend(VerboseQueryLogs) unless Rails.env.production?
    end
  end
end

