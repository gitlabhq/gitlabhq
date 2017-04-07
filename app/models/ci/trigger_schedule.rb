module Ci
  class TriggerSchedule < ActiveRecord::Base
    extend Ci::Model
    include Importable

    acts_as_paranoid

    belongs_to :project
    belongs_to :trigger

    validates :trigger, presence: { unless: :importing? }
    validates :cron, unless: :importing_or_inactive?, cron: true, presence: { unless: :importing_or_inactive? }
    validates :cron_timezone, cron_timezone: true, presence: { unless: :importing_or_inactive? }
    validates :ref, presence: { unless: :importing_or_inactive? }

    before_save :set_next_run_at

    scope :active, -> { where(active: true) }

    def importing_or_inactive?
      importing? || !active?
    end

    def set_next_run_at
      self.next_run_at = Gitlab::Ci::CronParser.new(cron, cron_timezone).next_time_from(Time.now)
    end

    def schedule_next_run!
      save! # with set_next_run_at
    rescue ActiveRecord::RecordInvalid
      update_attribute(:next_run_at, nil) # update without validation
    end

    def real_next_run(
        worker_cron: Settings.cron_jobs['trigger_schedule_worker']['cron'],
        worker_time_zone: Time.zone.name)
      Gitlab::Ci::CronParser.new(worker_cron, worker_time_zone)
                            .next_time_from(next_run_at)
    end
  end
end
