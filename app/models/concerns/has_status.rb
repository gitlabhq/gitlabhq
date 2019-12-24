# frozen_string_literal: true

module HasStatus
  extend ActiveSupport::Concern

  DEFAULT_STATUS = 'created'
  BLOCKED_STATUS = %w[manual scheduled].freeze
  AVAILABLE_STATUSES = %w[created waiting_for_resource preparing pending running success failed canceled skipped manual scheduled].freeze
  STARTED_STATUSES = %w[running success failed skipped manual scheduled].freeze
  ACTIVE_STATUSES = %w[preparing pending running].freeze
  COMPLETED_STATUSES = %w[success failed canceled skipped].freeze
  ORDERED_STATUSES = %w[failed preparing pending running waiting_for_resource manual scheduled canceled success skipped created].freeze
  PASSED_WITH_WARNINGS_STATUSES = %w[failed canceled].to_set.freeze
  EXCLUDE_IGNORED_STATUSES = %w[manual failed canceled].to_set.freeze
  STATUSES_ENUM = { created: 0, pending: 1, running: 2, success: 3,
                    failed: 4, canceled: 5, skipped: 6, manual: 7,
                    scheduled: 8, preparing: 9, waiting_for_resource: 10 }.freeze

  UnknownStatusError = Class.new(StandardError)

  class_methods do
    def legacy_status_sql
      scope_relevant = respond_to?(:exclude_ignored) ? exclude_ignored : all
      scope_warnings = respond_to?(:failed_but_allowed) ? failed_but_allowed : none

      builds = scope_relevant.select('count(*)').to_sql
      created = scope_relevant.created.select('count(*)').to_sql
      success = scope_relevant.success.select('count(*)').to_sql
      manual = scope_relevant.manual.select('count(*)').to_sql
      scheduled = scope_relevant.scheduled.select('count(*)').to_sql
      preparing = scope_relevant.preparing.select('count(*)').to_sql
      waiting_for_resource = scope_relevant.waiting_for_resource.select('count(*)').to_sql
      pending = scope_relevant.pending.select('count(*)').to_sql
      running = scope_relevant.running.select('count(*)').to_sql
      skipped = scope_relevant.skipped.select('count(*)').to_sql
      canceled = scope_relevant.canceled.select('count(*)').to_sql
      warnings = scope_warnings.select('count(*) > 0').to_sql.presence || 'false'

      Arel.sql(
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
          WHEN (#{waiting_for_resource})>0 THEN 'waiting_for_resource'
          WHEN (#{manual})>0 THEN 'manual'
          WHEN (#{scheduled})>0 THEN 'scheduled'
          WHEN (#{preparing})>0 THEN 'preparing'
          WHEN (#{created})>0 THEN 'running'
          ELSE 'failed'
        END)"
      )
    end

    def legacy_status
      all.pluck(legacy_status_sql).first
    end

    # This method should not be used.
    # This method performs expensive calculation of status:
    # 1. By plucking all related objects,
    # 2. Or executes expensive SQL query
    def slow_composite_status
      if Feature.enabled?(:ci_composite_status, default_enabled: false)
        Gitlab::Ci::Status::Composite
          .new(all, with_allow_failure: columns_hash.key?('allow_failure'))
          .status
      else
        legacy_status
      end
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
      state :waiting_for_resource, value: 'waiting_for_resource'
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

    scope :created, -> { with_status(:created) }
    scope :waiting_for_resource, -> { with_status(:waiting_for_resource) }
    scope :preparing, -> { with_status(:preparing) }
    scope :relevant, -> { without_status(:created) }
    scope :running, -> { with_status(:running) }
    scope :pending, -> { with_status(:pending) }
    scope :success, -> { with_status(:success) }
    scope :failed, -> { with_status(:failed) }
    scope :canceled, -> { with_status(:canceled) }
    scope :skipped, -> { with_status(:skipped) }
    scope :manual, -> { with_status(:manual) }
    scope :scheduled, -> { with_status(:scheduled) }
    scope :alive, -> { with_status(:created, :waiting_for_resource, :preparing, :pending, :running) }
    scope :alive_or_scheduled, -> { with_status(:created, :waiting_for_resource, :preparing, :pending, :running, :scheduled) }
    scope :created_or_pending, -> { with_status(:created, :pending) }
    scope :running_or_pending, -> { with_status(:running, :pending) }
    scope :finished, -> { with_status(:success, :failed, :canceled) }
    scope :failed_or_canceled, -> { with_status(:failed, :canceled) }
    scope :incomplete, -> { without_statuses(completed_statuses) }

    scope :cancelable, -> do
      where(status: [:running, :waiting_for_resource, :preparing, :pending, :created, :scheduled])
    end

    scope :without_statuses, -> (names) do
      with_status(all_state_names - names.to_a)
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
