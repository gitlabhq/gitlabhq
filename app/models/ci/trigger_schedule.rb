module Ci
  class TriggerSchedule < ActiveRecord::Base
    extend Ci::Model
    include Importable

    acts_as_paranoid

    belongs_to :project
    belongs_to :trigger

    delegate :ref, to: :trigger

    validates :trigger, presence: { unless: :importing? }
    validates :cron, cron: true, presence: { unless: :importing? }
    validates :cron_timezone, cron_timezone: true, presence: { unless: :importing? }
    validates :ref, presence: { unless: :importing? }

    before_save :set_next_run_at

    def set_next_run_at
      self.next_run_at = Gitlab::Ci::CronParser.new(cron, cron_timezone).next_time_from(Time.now)
    end

    def schedule_next_run!
      save! # with set_next_run_at
    rescue ActiveRecord::RecordInvalid
      update_attribute(:next_run_at, nil) # update without validation
    end
  end
end
