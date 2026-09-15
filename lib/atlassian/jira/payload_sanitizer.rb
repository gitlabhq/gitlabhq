# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- use existing module
module Atlassian
  module Jira
    # Strips characters Atlassian's Data Depot rejects from every string in a
    # Jira payload before it is posted.
    #
    # Atlassian's Data Depot rejects characters outside its accepted set with
    # "Invalid binary character '#xD83D' ...", failing the whole sync.
    # Astral code points (emoji, U+10000+) are valid XML 1.0 but Atlassian
    # re-encodes them as UTF-16 surrogates, which its XML store rejects.
    # Accepted set (Atlassian-specific, stricter than XML 1.0):
    #   #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD]
    # https://gitlab.com/gitlab-org/gitlab/-/work_items/565633
    class PayloadSanitizer
      INVALID_CHARS = /[^\x09\x0A\x0D\x20-\u{D7FF}\u{E000}-\u{FFFD}]/

      # Substituted when stripping would empty a non-empty string (e.g. a
      # project named only with emoji), so required fields such as `name` are
      # never sent blank. U+FFFD is inside Atlassian's accepted set.
      REPLACEMENT_CHAR = "\u{FFFD}"

      def self.sanitize(payload)
        new(payload).sanitize
      end

      def initialize(payload)
        @payload = payload
      end

      # Round-trip through JSON before sanitizing: `as_json` alone leaves
      # Grape entities as `NestingExposure::OutputBuilder` (a SimpleDelegator),
      # which `case/when Hash` does not match, so their strings would escape
      # sanitization. Parsing the serialized form guarantees plain hashes,
      # arrays and strings, and also decodes JSON-escaped control characters.
      #
      # If the payload exceeds `SafeParser` limits, fall back to the
      # unsanitized payload rather than failing the sync: no worse than before
      # sanitization existed, as an oversized payload is rejected at
      # Atlassian's end and handled gracefully by the client (413).
      def sanitize
        sanitize_value(Gitlab::Json::SafeParser.parse(@payload.to_json))
      rescue JSON::ParserError => error
        Gitlab::ErrorTracking.track_exception(error)

        @payload.as_json
      end

      private

      def sanitize_value(value)
        case value
        when String
          sanitized = value.gsub(INVALID_CHARS, '')
          sanitized.empty? && !value.empty? ? REPLACEMENT_CHAR : sanitized
        when Array
          value.map { |item| sanitize_value(item) }
        when Hash
          value.transform_values { |item| sanitize_value(item) }
        else
          value
        end
      end
    end
  end
end
# rubocop:enable Gitlab/BoundedContexts
