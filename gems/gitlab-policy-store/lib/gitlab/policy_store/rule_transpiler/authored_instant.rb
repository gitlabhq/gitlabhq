# frozen_string_literal: true

require "time"

module Gitlab
  module PolicyStore
    class RuleTranspiler
      class AuthoredInstant
        include InvalidatesViaCallable

        AUTHORED_WALL_CLOCK_FORMAT = "%Y-%m-%dT%H:%M:%S"

        EMITTED_TIMESTAMP_FORMAT = "%Y-%m-%dT%H:%M:%SZ"
        EMITTED_TIMESTAMP_PATTERN = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/

        # Anchored at both ends, so a bound `Time.iso8601` would read leniently is refused as
        # the wrong shape rather than reaching a later guard with a message about its meaning.
        # Case-insensitive because RFC 3339 lets both the separator and the `Z` be lowercase.
        AUTHORED_INSTANT_PATTERN = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})\z/i

        # A refusal has to cost less than the parse it prevents, and `Time.iso8601` accepts
        # a year of any width.
        MAX_AUTHORED_TIMESTAMP_LENGTH = 64

        def initialize(raw_value, field:, window_name:, invalid:, reported_value:)
          @raw_value = raw_value
          @field = field
          @window_name = window_name
          @invalid = invalid
          @reported_value = reported_value
        end

        def normalized
          parsed_value = parsed

          # `Time.iso8601` rolls an out-of-range component forward, so June 31 parses as
          # July 1 and a window authored for it would silently start a day late. Compared
          # case-insensitively, since RFC 3339 lets the separator be authored lowercase.
          unless raw_value.downcase.start_with?(parsed_value.strftime(AUTHORED_WALL_CLOCK_FORMAT).downcase)
            invalid!("calendar window #{reported_value(window_name)} #{field} names a date or time that " \
              "does not exist: #{reported_value(raw_value)}")
          end

          unless parsed_value.subsec.zero?
            invalid!("calendar window #{reported_value(window_name)} #{field} carries sub-second precision " \
              "the emitted comparison cannot represent: #{reported_value(raw_value)}")
          end

          emitted = parsed_value.getutc.strftime(EMITTED_TIMESTAMP_FORMAT)
          return emitted if EMITTED_TIMESTAMP_PATTERN.match?(emitted)

          invalid!("calendar window #{reported_value(window_name)} #{field} is outside the range the emitted " \
            "comparison can order: #{reported_value(raw_value)}")
        end

        private

        attr_reader :raw_value, :field, :window_name

        def parsed
          invalid!("calendar window #{reported_value(window_name)} requires #{field}") unless raw_value.is_a?(String)

          if raw_value.length > MAX_AUTHORED_TIMESTAMP_LENGTH
            invalid!("calendar window #{reported_value(window_name)} #{field} is longer than any instant: " \
              "#{reported_value(raw_value)}")
          end

          # The `Encoding::CompatibilityError` from matching an ASCII pattern against this is
          # not an `ArgumentError`, so the rescue below cannot turn it into a refusal.
          unless raw_value.ascii_only?
            invalid!("calendar window #{reported_value(window_name)} #{field} must be ASCII to be an " \
              "ISO 8601 instant, not #{raw_value.encoding}")
          end

          unless AUTHORED_INSTANT_PATTERN.match?(raw_value)
            invalid!("calendar window #{reported_value(window_name)} #{field} must be an RFC 3339 instant " \
              "such as `2026-12-24T00:00:00Z`: #{reported_value(raw_value)}")
          end

          Time.iso8601(raw_value)
        rescue ArgumentError
          invalid!("calendar window #{reported_value(window_name)} has an unparsable #{field}: " \
            "#{reported_value(raw_value)}")
        end
      end
    end
  end
end
