# frozen_string_literal: true

module HasStatus
  extend ActiveSupport::Concern

  DEFAULT_STATUS = 'created'.freeze
  BLOCKED_STATUS = %w[manual scheduled].freeze
  AVAILABLE_STATUSES = %w[created preparing pending running success failed canceled skipped manual scheduled].freeze
  STARTED_STATUSES = %w[running success failed skipped manual scheduled].freeze
  ACTIVE_STATUSES = %w[preparing pending running].freeze
  COMPLETED_STATUSES = %w[success failed canceled skipped].freeze
  ORDERED_STATUSES = %w[failed preparing pending running manual scheduled canceled success skipped created].freeze
  STATUSES_ENUM = { created: 0, pending: 1, running: 2, success: 3,
                    failed: 4, canceled: 5, skipped: 6, manual: 7,
                    scheduled: 8, preparing: 9 }.freeze

  UnknownStatusError = Class.new(StandardError)

  class_methods do
    def status_sql
      scope_relevant = respond_to?(:exclude_ignored) ? exclude_ignored : all
      scope_warnings = respond_to?(:failed_but_allowed) ? failed_but_allowed : none

      builds = scope_relevant.select('count(*)').to_sql
      created = scope_relevant.created.select('count(*)').to_sql
      success = scope_relevant.success.select('count(*)').to_sql
      manual = scope_relevant.manual.select('count(*)').to_sql
      scheduled = scope_relevant.scheduled.select('count(*)').to_sql
      preparing = scope_relevant.preparing.select('count(*)').to_sql
      pending = scope_relevant.pending.select('count(*)').to_sql
      running = scope_relevant.running.select('count(*)').to_sql
      skipped = scope_relevant.skipped.select('count(*)').to_sql
      canceled = scope_relevant.canceled.select('count(*)').to_sql
      warnings = scope_warnings.select('count(*) > 0').to_sql.presence || 'false'

      "(CASE
        WHEN (#{builds})=(#{skipped}) AND (#{warnings}) THEN 'success'
        WHEN (#{builds})=(#{skipped}) THEN 'skipped'
        WHEN (#{builds})=(#{success}) THEN 'success'
        WHEN (#{builds})=(#{created}) THEN 'created'
        WHEN (#{builds})=(#{preparing}) THEN 'preparing'
        WHEN (#{builds})=(#{success})+(#{skipped}) THEN 'success'
        WHEN (#{builds})=(#{success})+(#{skipped})+(#{canceled}) THEN 'canceled'
        WHEN (#{builds})=(#{created})+(#{skipped})+(#{pending}) THEN 'pending'
        WHEN (#{running})+(#{pending})>0 THEN 'running'
        WHEN (#{manual})>0 THEN 'manual'
        WHEN (#{scheduled})>0 THEN 'scheduled'
        WHEN (#{preparing})>0 THEN 'preparing'
        WHEN (#{created})>0 THEN 'running'
        ELSE 'failed'
      END)"
    end

    def status
      all.pluck(status_sql).first
    end

    def started_at
      all.minimum(:started_at)
    end

    def finished_at
      all.maximum(:finished_at)
    end

    def all_state_names
      state_machines.values.flat_map(&:states).flat_map { |s| s.map(&:name) }
    end

    def completed_statuses
      COMPLETED_STATUSES.map(&:to_sym)
    end
  end

  included do
    validates :status, inclusion: { in: AVAILABLE_STATUSES }

    state_machine :status, initial: :created do
      state :created, value: 'created'
      state :preparing, value: 'preparing'
      state :pending, value: 'pending'
      state :running, value: 'running'
      state :failed, value: 'failed'
      state :success, value: 'success'
      state :canceled, value: 'canceled'
      state :skipped, value: 'skipped'
      state :manual, value: 'manual'
      state :scheduled, value: 'scheduled'
    end

    scope :created, -> { where(status: 'created') }
    scope :preparing, -> { where(status: 'preparing') }
    scope :relevant, -> { where(status: AVAILABLE_STATUSES - ['created']) }
    scope :running, -> { where(status: 'running') }
    scope :pending, -> { where(status: 'pending') }
    scope :success, -> { where(status: 'success') }
    scope :failed, -> { where(status: 'failed') }
    scope :canceled, -> { where(status: 'canceled') }
    scope :skipped, -> { where(status: 'skipped') }
    scope :manual, -> { where(status: 'manual') }
    scope :scheduled, -> { where(status: 'scheduled') }
    scope :alive, -> { where(status: [:created, :preparing, :pending, :running]) }
    scope :created_or_pending, -> { where(status: [:created, :pending]) }
    scope :running_or_pending, -> { where(status: [:running, :pending]) }
    scope :finished, -> { where(status: [:success, :failed, :canceled]) }
    scope :failed_or_canceled, -> { where(status: [:failed, :canceled]) }

    scope :cancelable, -> do
      where(status: [:running, :preparing, :pending, :created, :scheduled])
    end
  end

  def started?
    STARTED_STATUSES.include?(status) && started_at
  end

  def active?
    ACTIVE_STATUSES.include?(status)
  end

  def complete?
    COMPLETED_STATUSES.include?(status)
  end

  def blocked?
    BLOCKED_STATUS.include?(status)
  end

  private

  def calculate_duration
    if started_at && finished_at
      finished_at - started_at
    elsif started_at
      Time.now - started_at
    end
  end
end
