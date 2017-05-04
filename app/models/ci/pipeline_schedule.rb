module Ci
  class PipelineSchedule < ActiveRecord::Base
    extend Ci::Model
    include Importable

    acts_as_paranoid

    belongs_to :project
    belongs_to :owner, class_name: 'User'
    has_many :pipelines

    validates :cron, unless: :importing_or_inactive?, cron: true, presence: { unless: :importing_or_inactive? }
    validates :cron_timezone, cron_timezone: true, presence: { unless: :importing_or_inactive? }
    validates :ref, presence: { unless: :importing_or_inactive? }
    validates :description, presence: true

    before_save :set_next_run_at

    scope :active, -> { where(active: true) }
    scope :inactive, -> { where(active: false) }

    def owned_by?(current_user)
      owner == current_user
    end

    def can_take_ownership?(current_user)
      Ability.allowed?(current_user, :update_pipeline_schedule, project) &&
        !owned_by?(current_user)
    end

    def last_pipeline
      pipelines.last
    end

    def inactive?
      !active?
    end

    def importing_or_inactive?
      importing? || inactive?
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
