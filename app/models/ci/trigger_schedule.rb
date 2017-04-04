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
    validates :cron_time_zone, cron_time_zone: true, presence: { unless: :importing? }
    validates :ref, presence: { unless: :importing? }

    after_create :schedule_next_run!

    def schedule_next_run!
      next_time = Gitlab::Ci::CronParser.new(cron, cron_time_zone).next_time_from(Time.now)
      update!(next_run_at: next_time) if next_time.present?
    end
  end
end
