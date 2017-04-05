module Gitlab
  module Ci
    class CronParser
      VALID_SYNTAX_SAMPLE_TIME_ZONE = 'UTC'.freeze
      VALID_SYNTAX_SAMPLE_CRON = '* * * * *'.freeze

      def initialize(cron, cron_timezone = 'UTC')
        @cron = cron
        @cron_timezone = cron_timezone
      end

      def next_time_from(time)
        @cron_line ||= try_parse_cron(@cron, @cron_timezone)
        @cron_line.next_time(time).in_time_zone(Time.zone) if @cron_line.present?
      end

      def cron_valid?
        try_parse_cron(@cron, VALID_SYNTAX_SAMPLE_TIME_ZONE).present?
      end

      def cron_timezone_valid?
        try_parse_cron(VALID_SYNTAX_SAMPLE_CRON, @cron_timezone).present?
      end

      private

      def try_parse_cron(cron, cron_timezone)
        Rufus::Scheduler.parse("#{cron} #{cron_timezone}")
      rescue
        # noop
      end
    end
  end
end
