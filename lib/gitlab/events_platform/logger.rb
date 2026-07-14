# frozen_string_literal: true

module Gitlab
  module EventsPlatform
    # Structured JSON logger for the Events Platform consumer; writes to `log/events_platform.log`.
    # The subscriber runs as a long-lived loop outside any request, so request-context fields would
    # be stale - exclude them.
    class Logger < ::Gitlab::JsonLogger
      exclude_context!

      def self.file_name_noext
        'events_platform'
      end
    end
  end
end
