module HasStatus
  extend ActiveSupport::Concern

  AVAILABLE_STATUSES = %w[created pending running success failed canceled skipped]
  STARTED_STATUSES = %w[running success failed skipped]
  ACTIVE_STATUSES = %w[pending running]
  COMPLETED_STATUSES = %w[success failed canceled]

  class_methods do
    def status_sql
      scope = if respond_to?(:exclude_ignored)
                exclude_ignored
              else
                all
              end
      builds = scope.select('count(*)').to_sql
      created = scope.created.select('count(*)').to_sql
      success = scope.success.select('count(*)').to_sql
      pending = scope.pending.select('count(*)').to_sql
      running = scope.running.select('count(*)').to_sql
      skipped = scope.skipped.select('count(*)').to_sql
      canceled = scope.canceled.select('count(*)').to_sql

      "(CASE
        WHEN (#{builds})=(#{success}) THEN 'success'
        WHEN (#{builds})=(#{created}) THEN 'created'
        WHEN (#{builds})=(#{success})+(#{skipped}) THEN 'skipped'
        WHEN (#{builds})=(#{success})+(#{skipped})+(#{canceled}) THEN 'canceled'
        WHEN (#{builds})=(#{created})+(#{skipped})+(#{pending}) THEN 'pending'
        WHEN (#{running})+(#{pending})+(#{created})>0 THEN 'running'
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
  end

  included do
    validates :status, inclusion: { in: AVAILABLE_STATUSES }

    state_machine :status, initial: :created do
      state :created, value: 'created'
      state :pending, value: 'pending'
      state :running, value: 'running'
      state :failed, value: 'failed'
      state :success, value: 'success'
      state :canceled, value: 'canceled'
      state :skipped, value: 'skipped'
    end

    scope :created, -> { where(status: 'created') }
    scope :relevant, -> { where.not(status: 'created') }
    scope :running, -> { where(status: 'running') }
    scope :pending, -> { where(status: 'pending') }
    scope :success, -> { where(status: 'success') }
    scope :failed, -> { where(status: 'failed')  }
    scope :canceled, -> { where(status: 'canceled')  }
    scope :skipped, -> { where(status: 'skipped')  }
    scope :running_or_pending, -> { where(status: [:running, :pending]) }
    scope :finished, -> { where(status: [:success, :failed, :canceled]) }
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

  private

  def calculate_duration
    if started_at && finished_at
      finished_at - started_at
    elsif started_at
      Time.now - started_at
    end
  end
end
