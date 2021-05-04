# frozen_string_literal: true

module Grafana
  # Allows for easy formatting and manipulations of timestamps
  # coming from a Grafana url
  class TimeWindow
    include ::Gitlab::Utils::StrongMemoize

    def initialize(from, to)
      @from = from
      @to = to
    end

    def formatted
      {
        start: window[:from].formatted,
        end: window[:to].formatted
      }
    end

    def in_milliseconds
      window.transform_values(&:to_ms)
    end

    private

    def window
      strong_memoize(:window) do
        specified_window
      rescue Timestamp::Error
        default_window
      end
    end

    def specified_window
      RangeWithDefaults.new(
        from: Timestamp.from_ms_since_epoch(@from),
        to: Timestamp.from_ms_since_epoch(@to)
      ).to_hash
    end

    def default_window
      RangeWithDefaults.new.to_hash
    end
  end

  # For incomplete time ranges, adds default parameters to
  # achieve a complete range. If both full range is provided,
  # range will be returned.
  class RangeWithDefaults
    DEFAULT_RANGE = 8.hours

    # @param from [Grafana::Timestamp, nil] Start of the expected range
    # @param to [Grafana::Timestamp, nil] End of the expected range
    def initialize(from: nil, to: nil)
      @from = from
      @to = to

      apply_defaults!
    end

    def to_hash
      { from: @from, to: @to }.compact
    end

    private

    def apply_defaults!
      @to ||= @from ? relative_end : Timestamp.new(Time.now)
      @from ||= relative_start
    end

    def relative_start
      Timestamp.new(DEFAULT_RANGE.before(@to.time))
    end

    def relative_end
      Timestamp.new(DEFAULT_RANGE.since(@from.time))
    end
  end

  # Offers a consistent API for timestamps originating from
  # Grafana or other sources, allowing for formatting of timestamps
  # as consumed by Grafana-related utilities
  class Timestamp
    Error = Class.new(StandardError)

    attr_accessor :time

    # @param timestamp [Time]
    def initialize(time)
      @time = time
    end

    # Formats a timestamp from Grafana for compatibility with
    # parsing in JS via `new Date(timestamp)`
    def formatted
      time.utc.strftime('%FT%TZ')
    end

    # Converts to milliseconds since epoch
    def to_ms
      time.to_i * 1000
    end

    class << self
      # @param time [String] Representing milliseconds since epoch.
      #                      This is what JS "decided" unix is.
      def from_ms_since_epoch(time)
        return if time.nil?

        raise Error, 'Expected milliseconds since epoch' unless ms_since_epoch?(time)

        new(cast_ms_to_time(time))
      end

      private

      def cast_ms_to_time(time)
        Time.at(time.to_i / 1000.0)
      end

      def ms_since_epoch?(time)
        ms = time.to_i

        ms.to_s == time && ms.bit_length < 64
      end
    end
  end
end
