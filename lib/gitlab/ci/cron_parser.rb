# frozen_string_literal: true

module Gitlab
  module Ci
    class CronParser
      VALID_SYNTAX_SAMPLE_TIME_ZONE = 'UTC'
      VALID_SYNTAX_SAMPLE_CRON = '* * * * *'

      def self.parse_natural(expression, cron_timezone = 'UTC')
        new(Fugit::Nat.parse(expression)&.original, cron_timezone)
      end

      def initialize(cron, cron_timezone = 'UTC')
        @cron = cron
        @cron_timezone = timezone_name(cron_timezone)
      end

      def next_time_from(time)
        cron_line.next_time(time).utc.in_time_zone(Time.zone) if cron_line.present?
      end

      def previous_time_from(time)
        cron_line.previous_time(time).utc.in_time_zone(Time.zone) if cron_line.present?
      end

      def cron_valid?
        try_parse_cron(@cron, VALID_SYNTAX_SAMPLE_TIME_ZONE).present?
      end

      def cron_timezone_valid?
        try_parse_cron(VALID_SYNTAX_SAMPLE_CRON, @cron_timezone).present?
      end

      def match?(time)
        cron_line.match?(time)
      end

      private

      def timezone_name(timezone)
        ActiveSupport::TimeZone.find_tzinfo(timezone).name
      rescue TZInfo::InvalidTimezoneIdentifier
        timezone
      end

      # NOTE:
      # cron_timezone can only accept timezones listed in TZInfo::Timezone.
      # Aliases of Timezones from ActiveSupport::TimeZone are NOT accepted,
      # because Fugit::Cron only supports TZInfo::Timezone.
      #
      # For example, those codes have the same effect.
      # Time.zone = 'Pacific Time (US & Canada)' (ActiveSupport::TimeZone)
      # Time.zone = 'America/Los_Angeles' (TZInfo::Timezone)
      #
      # However, try_parse_cron only accepts the latter format.
      # try_parse_cron('* * * * *', 'Pacific Time (US & Canada)') -> Doesn't work
      # try_parse_cron('* * * * *', 'America/Los_Angeles') -> Works
      # If you want to know more, please take a look
      # https://github.com/rails/rails/blob/master/activesupport/lib/active_support/values/time_zone.rb
      def try_parse_cron(cron, cron_timezone)
        Fugit::Cron.parse("#{cron} #{cron_timezone}")
      end

      def cron_line
        @cron_line ||= try_parse_cron(@cron, @cron_timezone)
      end
    end
  end
end
