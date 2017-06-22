module Ci
  class PipelineSchedule < ActiveRecord::Base
    extend Ci::Model
    include Importable

    acts_as_paranoid

    belongs_to :project
    belongs_to :owner, class_name: 'User'
    has_one :last_pipeline, -> { order(id: :desc) }, class_name: 'Ci::Pipeline'
    has_many :pipelines
    has_many :variables, :dependent => :destroy, class_name: 'Ci::PipelineScheduleVariable'

    validates :cron, unless: :importing?, cron: true, presence: { unless: :importing? }
    validates :cron_timezone, cron_timezone: true, presence: { unless: :importing? }
    validates :ref, presence: { unless: :importing? }
    validates :description, presence: true
    validates_associated :variables

    before_save :set_next_run_at

    scope :active, -> { where(active: true) }
    scope :inactive, -> { where(active: false) }

    accepts_nested_attributes_for :variables, allow_destroy: true

    before_validation(on: :update) do
      # TODO: if validation failed, restore the deleted_obj
      deleted_obj = Ci::PipelineScheduleVariable.where(pipeline_schedule_id: self).destroy_all
    end

    after_validation(on: :update) do
      # TODO: if validation failed, restore the deleted_obj
    end

    def owned_by?(current_user)
      owner == current_user
    end

    def own!(user)
      update(owner: user)
    end

    def inactive?
      !active?
    end

    def deactivate!
      update_attribute(:active, false)
    end

    def runnable_by_owner?
      Ability.allowed?(owner, :create_pipeline, project)
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
        worker_cron: Settings.cron_jobs['pipeline_schedule_worker']['cron'],
        worker_time_zone: Time.zone.name)
      Gitlab::Ci::CronParser.new(worker_cron, worker_time_zone)
                            .next_time_from(next_run_at)
    end
  end
end
