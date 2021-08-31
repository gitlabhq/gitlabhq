# frozen_string_literal: true

module Gitlab
  module Ci
    class CronParser
      VALID_SYNTAX_SAMPLE_TIME_ZONE = 'UTC'
      VALID_SYNTAX_SAMPLE_CRON = '* * * * *'

      class << self
        def parse_natural(expression, cron_timezone = 'UTC')
          new(Fugit::Nat.parse(expression)&.original, cron_timezone)
        end

        # This method generates compatible expressions that can be
        # parsed by Fugit::Nat.parse to generate a cron line.
        # It takes start date of the cron and cadence in the following format:
        # cadence = {
        #   unit: 'day/week/month/year'
        #   duration: 1
        # }
        def parse_natural_with_timestamp(starts_at, cadence)
          case cadence[:unit]
          when 'day' # Currently supports only 'every 1 day'.
            "#{starts_at.min} #{starts_at.hour} * * *"
          when 'week' # Currently supports only 'every 1 week'.
            "#{starts_at.min} #{starts_at.hour} * * #{starts_at.wday}"
          when 'month'
            unless [1, 3, 6, 12].include?(cadence[:duration])
              raise NotImplementedError, "The cadence #{cadence} is not supported"
            end

            "#{starts_at.min} #{starts_at.hour} #{starts_at.mday} #{fall_in_months(cadence[:duration], starts_at)} *"
          when 'year' # Currently supports only 'every 1 year'.
            "#{starts_at.min} #{starts_at.hour} #{starts_at.mday} #{starts_at.month} *"
          else
            raise NotImplementedError, "The cadence unit #{cadence[:unit]} is not implemented"
          end
        end

        def fall_in_months(offset, start_date)
          (1..(12 / offset)).map { |i| start_date.next_month(offset * i).month }.join(',')
        end
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
