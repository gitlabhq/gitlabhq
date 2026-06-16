# frozen_string_literal: true

module API
  module Helpers
    module Packages
      # Shared helpers for turning GitLab's standard API error messages
      # ("NNN StatusPhrase - detail") into strings that package clients can
      # surface to end users. Mixed into the per-format error helpers (e.g.
      # Maven::ApiErrorFormatter, Rubygems::ErrorMessageHeader) via `include`.
      module ErrorMessage
        # Matches "NNN StatusPhrase - detail" (produced by render_api_error_with_reason!)
        # and captures the trailing detail.
        REASON_PHRASE_REGEX = /\A\d{3}\s.+?\s-\s(.+)\z/

        # Returns the detail portion of a "NNN StatusPhrase - detail" message, or nil
        # when the message is not in that form (bare status phrase, blank, or non-string).
        def error_message_detail(message)
          return unless message.is_a?(String)

          match = message.match(REASON_PHRASE_REGEX)
          match && match[1]
        end

        # Collapses CR/LF so an error message is safe to use as a single-line HTTP header value.
        def error_message_single_line(value)
          value.to_s.tr("\r\n", ' ')
        end
      end
    end
  end
end
