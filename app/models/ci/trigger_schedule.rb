module Ci
  class TriggerSchedule < ActiveRecord::Base
    extend Ci::Model

    acts_as_paranoid

    belongs_to :project
    belongs_to :trigger

    def schedule_next_run!
      next_time = Ci::CronParser.new(cron, cron_time_zone).next_time_from_now
      if next_time.present?
        update_attributes(next_run_at: next_time)
      end
    end

    # def update_last_run!
    #   update_attributes(last_run_at: Time.now)
    # end
  end
end
