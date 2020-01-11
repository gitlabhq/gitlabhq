# frozen_string_literal: true

module Ci
  class PipelineSchedule < ApplicationRecord
    extend Gitlab::Ci::Model
    include Importable
    include StripAttribute
    include Schedulable

    belongs_to :project
    belongs_to :owner, class_name: 'User'
    has_one :last_pipeline, -> { order(id: :desc) }, class_name: 'Ci::Pipeline'
    has_many :pipelines
    has_many :variables, class_name: 'Ci::PipelineScheduleVariable', validate: false

    validates :cron, unless: :importing?, cron: true, presence: { unless: :importing? }
    validates :cron_timezone, cron_timezone: true, presence: { unless: :importing? }
    validates :ref, presence: { unless: :importing? }
    validates :description, presence: true
    validates :variables, variable_duplicates: true

    strip_attributes :cron

    scope :active, -> { where(active: true) }
    scope :inactive, -> { where(active: false) }
    scope :preloaded, -> { preload(:owner, :project) }

    accepts_nested_attributes_for :variables, allow_destroy: true

    alias_attribute :real_next_run, :next_run_at

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

    ##
    # The `next_run_at` column is set to the actual execution date of `PipelineScheduleWorker`.
    # This way, a schedule like `*/1 * * * *` won't be triggered in a short interval
    # when PipelineScheduleWorker runs irregularly by Sidekiq Memory Killer.
    def set_next_run_at
      now = Time.zone.now
      ideal_next_run = ideal_next_run_from(now)

      self.next_run_at = if ideal_next_run == cron_worker_next_run_from(now)
                           ideal_next_run
                         else
                           cron_worker_next_run_from(ideal_next_run)
                         end
    end

    def job_variables
      variables&.map(&:to_runner_variable) || []
    end

    private

    def ideal_next_run_from(start_time)
      Gitlab::Ci::CronParser.new(cron, cron_timezone)
                            .next_time_from(start_time)
    end

    def cron_worker_next_run_from(start_time)
      Gitlab::Ci::CronParser.new(Settings.cron_jobs['pipeline_schedule_worker']['cron'],
                                Time.zone.name)
                            .next_time_from(start_time)
    end
  end
end

Ci::PipelineSchedule.prepend_if_ee('EE::Ci::PipelineSchedule')
