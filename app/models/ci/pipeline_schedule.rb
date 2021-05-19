# frozen_string_literal: true

module Ci
  class PipelineSchedule < ApplicationRecord
    extend Gitlab::Ci::Model
    include Importable
    include StripAttribute
    include CronSchedulable
    include Limitable
    include EachBatch

    self.limit_name = 'ci_pipeline_schedules'
    self.limit_scope = :project

    belongs_to :project
    belongs_to :owner, class_name: 'User'
    has_one :last_pipeline, -> { order(id: :desc) }, class_name: 'Ci::Pipeline'
    has_many :pipelines
    has_many :variables, class_name: 'Ci::PipelineScheduleVariable', validate: false

    validates :cron, unless: :importing?, cron: true, presence: { unless: :importing? }
    validates :cron_timezone, cron_timezone: true, presence: { unless: :importing? }
    validates :ref, presence: { unless: :importing? }
    validates :description, presence: true
    validates :variables, nested_attributes_duplicates: true

    strip_attributes :cron

    scope :active, -> { where(active: true) }
    scope :inactive, -> { where(active: false) }
    scope :preloaded, -> { preload(:owner, project: [:route]) }
    scope :owned_by, ->(user) { where(owner: user) }

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

    def job_variables
      variables&.map(&:to_runner_variable) || []
    end

    private

    def worker_cron_expression
      Settings.cron_jobs['pipeline_schedule_worker']['cron']
    end
  end
end

Ci::PipelineSchedule.prepend_mod_with('Ci::PipelineSchedule')
