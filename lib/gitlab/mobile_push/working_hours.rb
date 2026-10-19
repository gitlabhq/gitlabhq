# frozen_string_literal: true

module Gitlab
  module MobilePush
    # A user's working hours for mobile push: a daily window in minutes after
    # local midnight, the weekdays it applies to and the IANA zone it is
    # defined in. Fails open: a schedule it cannot evaluate delivers.
    class WorkingHours
      # ISO order, so index 0 is Monday and index 6 is Sunday.
      DAYS = %w[monday tuesday wednesday thursday friday saturday sunday].freeze

      Window = Data.define(:start_minute, :end_minute) do
        def usable?
          start_minute.present? && end_minute.present? && start_minute != end_minute
        end

        # An end before the start crosses midnight (night shifts).
        def overnight?
          end_minute < start_minute
        end
      end

      def initialize(window:, days:, zone:)
        @window = window
        @days = Array(days).map(&:to_s) & DAYS
        @zone = zone
      end

      # Both times set and different, at least one known day, a zone Rails knows.
      def usable?
        window.usable? && days.any? && zone.present?
      end

      # The end is exclusive, so 09:00-17:00 stops at 16:59.
      def deliver_now?(now = Time.current)
        return true unless usable?

        local = now.in_time_zone(zone)
        minute = (local.hour * 60) + local.min

        if window.overnight?
          # The part after the start belongs to today, the part before the end
          # to the working day that began yesterday.
          (working_day?(local.wday) && minute >= window.start_minute) ||
            (working_day?(local.wday - 1) && minute < window.end_minute)
        else
          working_day?(local.wday) && minute >= window.start_minute && minute < window.end_minute
        end
      end

      # The next moment the window opens, in UTC: today at the start if that is
      # still ahead on a working day, else the start of the next working day.
      # TimeZone#local moves a start inside a DST gap one hour later.
      def next_window_start(now = Time.current)
        return unless usable?

        local = now.in_time_zone(zone)

        # At least one weekday is set, so the same weekday a week ahead always qualifies.
        (0..7).lazy
          .map { |offset| local.to_date + offset }
          .select { |day| working_day?(day.wday) }
          .map { |day| window_start_on(day) }
          .find { |start| start > local }
          .utc
      end

      private

      attr_reader :window, :days, :zone

      # Ruby's wday is 0 = Sunday .. 6 = Saturday; DAYS is ISO Monday..Sunday.
      def working_day?(wday)
        days.include?(DAYS[(wday + 6) % 7])
      end

      def window_start_on(day)
        zone.local(day.year, day.month, day.day, window.start_minute / 60, window.start_minute % 60)
      end
    end
  end
end
