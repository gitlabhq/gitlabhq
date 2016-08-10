module Statuseable
  extend ActiveSupport::Concern

  AVAILABLE_STATUSES = %w(pending running success failed canceled skipped)

  class_methods do
    def status_sql
      builds = all.select('count(*)').to_sql
      success = all.success.select('count(*)').to_sql
      ignored = all.ignored.select('count(*)').to_sql if all.respond_to?(:ignored)
      ignored ||= '0'
      pending = all.pending.select('count(*)').to_sql
      running = all.running.select('count(*)').to_sql
      canceled = all.canceled.select('count(*)').to_sql
      skipped = all.skipped.select('count(*)').to_sql

      deduce_status = "(CASE
        WHEN (#{builds})=0 THEN NULL
        WHEN (#{builds})=(#{skipped}) THEN 'skipped'
        WHEN (#{builds})=(#{success})+(#{ignored})+(#{skipped}) THEN 'success'
        WHEN (#{builds})=(#{pending})+(#{skipped}) THEN 'pending'
        WHEN (#{builds})=(#{canceled})+(#{success})+(#{ignored})+(#{skipped}) THEN 'canceled'
        WHEN (#{running})+(#{pending})>0 THEN 'running'
        ELSE 'failed'
      END)"

      deduce_status
    end

    def status
      all.pluck(self.status_sql).first
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

    state_machine :status, initial: :pending do
      state :pending, value: 'pending'
      state :running, value: 'running'
      state :failed, value: 'failed'
      state :success, value: 'success'
      state :canceled, value: 'canceled'
      state :skipped, value: 'skipped'
    end

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
    !pending? && !canceled? && started_at
  end

  def active?
    running? || pending?
  end

  def complete?
    canceled? || success? || failed?
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
