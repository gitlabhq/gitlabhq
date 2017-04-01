module Ci
  class TriggerSchedule < ActiveRecord::Base
    extend Ci::Model

    acts_as_paranoid

    belongs_to :project
    belongs_to :trigger

    delegate :ref, to: :trigger

    validates :trigger, presence: true
    validates :cron, cron: true, presence: true
    validates :cron_time_zone, presence: true
    validates :ref, ref: true, presence: true
    # validate :check_cron_frequency

    after_create :schedule_next_run!

    def schedule_next_run!
      next_time = Ci::CronParser.new(cron, cron_time_zone).next_time_from(Time.now)

      # if next_time.present? && !less_than_1_hour_from_now?(next_time)
      if next_time.present?
        update!(next_run_at: next_time)
      end
    end

    # private

    # def less_than_1_hour_from_now?(time)
    #   puts "diff: #{(time - Time.now).abs.inspect}"
    #   ((time - Time.now).abs < 1.hour) ? true : false
    # end

    # def check_cron_frequency
    #   next_time = Ci::CronParser.new(cron, cron_time_zone).next_time_from(Time.now)

    #   if less_than_1_hour_from_now?(next_time)
    #     self.errors.add(:cron, " can not be less than 1 hour")
    #   end
    # end
  end
end
