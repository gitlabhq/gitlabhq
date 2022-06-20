# frozen_string_literal: true

class MergeRequest::CleanupSchedule < ApplicationRecord
  STATUSES = {
    unstarted: 0,
    running: 1,
    completed: 2,
    failed: 3
  }.freeze

  # NOTE: Limit the number of stuck schedule jobs to retry just in case it becomes too big.
  STUCK_RETRY_LIMIT = 5

  belongs_to :merge_request, inverse_of: :cleanup_schedule

  validates :scheduled_at, presence: true

  state_machine :status, initial: :unstarted do
    state :unstarted, value: STATUSES[:unstarted]
    state :running, value: STATUSES[:running]
    state :completed, value: STATUSES[:completed]
    state :failed, value: STATUSES[:failed]

    event :run do
      transition unstarted: :running
    end

    event :retry do
      transition running: :unstarted
    end

    event :complete do
      transition running: :completed
    end

    event :mark_as_failed do
      transition running: :failed
    end

    before_transition to: [:completed] do |cleanup_schedule, _transition|
      cleanup_schedule.completed_at = Time.current
    end

    before_transition from: :running, to: [:unstarted, :failed] do |cleanup_schedule, _transition|
      cleanup_schedule.failed_count += 1
    end
  end

  scope :scheduled_and_unstarted, -> {
    where('completed_at IS NULL AND scheduled_at <= NOW() AND status = ?', STATUSES[:unstarted])
      .order('scheduled_at DESC')
  }

  # NOTE: It is considered stuck as it is unusual to take more than 6 hours to finish the cleanup task.
  scope :stuck, -> {
    where('updated_at <= NOW() - interval \'6 hours\' AND status = ?', STATUSES[:running])
  }

  def self.start_next
    MergeRequest::CleanupSchedule.transaction do
      cleanup_schedule = scheduled_and_unstarted.lock('FOR UPDATE SKIP LOCKED').first

      next if cleanup_schedule.blank?

      cleanup_schedule.run!
      cleanup_schedule
    end
  end

  def self.stuck_retry!
    self.stuck.limit(STUCK_RETRY_LIMIT).map(&:retry!)
  end
end
