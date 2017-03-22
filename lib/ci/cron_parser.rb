require 'rufus-scheduler' # Included in sidekiq-cron

module Ci
  class CronParser
    def initialize(cron, cron_time_zone = 'UTC')
      @cron = cron
      @cron_time_zone = cron_time_zone
    end

    def next_time_from_now
      cronLine = try_parse_cron
      return nil unless cronLine.present?
      cronLine.next_time
    end

    def valid_syntax?
      try_parse_cron.present? ? true : false
    end

    private

    def try_parse_cron
      begin
        Rufus::Scheduler.parse("#{@cron} #{@cron_time_zone}")
      rescue
        nil
      end
    end
  end
end
