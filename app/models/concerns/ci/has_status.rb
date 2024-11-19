# frozen_string_literal: true

module Ci
  module HasStatus
    extend ActiveSupport::Concern

    DEFAULT_STATUS = 'created'
    BLOCKED_STATUS = %w[manual scheduled].freeze
    AVAILABLE_STATUSES = %w[
      created
      waiting_for_resource
      preparing
      waiting_for_callback
      pending
      running
      success
      failed
      canceling
      canceled
      skipped
      manual
      scheduled
    ].freeze
    STARTED_STATUSES = %w[running success failed].freeze
    ACTIVE_STATUSES = %w[waiting_for_resource preparing waiting_for_callback pending running].freeze
    COMPLETED_STATUSES = %w[success failed canceled skipped].freeze
    COMPLETED_WITH_MANUAL_STATUSES = COMPLETED_STATUSES + %w[manual]
    STOPPED_STATUSES = COMPLETED_STATUSES + BLOCKED_STATUS
    ORDERED_STATUSES = %w[
      failed
      preparing
      pending
      running
      waiting_for_callback
      waiting_for_resource
      manual
      scheduled
      canceling
      canceled
      success
      skipped
      created
    ].freeze
    PASSED_WITH_WARNINGS_STATUSES = %w[failed canceled].to_set.freeze
    IGNORED_STATUSES = %w[manual].to_set.freeze
    EXECUTING_STATUSES = %w[running canceling].freeze
    ALIVE_STATUSES = ORDERED_STATUSES - COMPLETED_STATUSES - BLOCKED_STATUS
    CANCELABLE_STATUSES = (ALIVE_STATUSES + ['scheduled'] - ['canceling']).freeze
    STATUSES_ENUM = { created: 0, pending: 1, running: 2, success: 3,
                      failed: 4, canceled: 5, skipped: 6, manual: 7,
                      scheduled: 8, preparing: 9, waiting_for_resource: 10,
                      waiting_for_callback: 11, canceling: 12 }.freeze

    UnknownStatusError = Class.new(StandardError)

    class_methods do
      # This will be removed with ci_remove_ensure_stage_service
      def composite_status
        Gitlab::Ci::Status::Composite
          .new(all, with_allow_failure: columns_hash.key?('allow_failure'))
          .status
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

      def completed_with_manual_statuses
        COMPLETED_WITH_MANUAL_STATUSES.map(&:to_sym)
      end

      def stopped_statuses
        STOPPED_STATUSES.map(&:to_sym)
      end
    end

    included do
      validates :status, inclusion: { in: AVAILABLE_STATUSES }

      state_machine :status, initial: :created do
        state :created, value: 'created'
        state :waiting_for_resource, value: 'waiting_for_resource'
        state :preparing, value: 'preparing'
        state :waiting_for_callback, value: 'waiting_for_callback'
        state :pending, value: 'pending'
        state :running, value: 'running'
        state :failed, value: 'failed'
        state :success, value: 'success'
        state :canceled, value: 'canceled'
        state :canceling, value: 'canceling'
        state :skipped, value: 'skipped'
        state :manual, value: 'manual'
        state :scheduled, value: 'scheduled'
      end

      scope :created, -> { with_status(:created) }
      scope :waiting_for_resource, -> { with_status(:waiting_for_resource) }
      scope :preparing, -> { with_status(:preparing) }
      scope :relevant, -> { without_status(:created) }
      scope :waiting_for_callback, -> { with_status(:waiting_for_callback) }
      scope :running, -> { with_status(:running) }
      scope :pending, -> { with_status(:pending) }
      scope :success, -> { with_status(:success) }
      scope :failed, -> { with_status(:failed) }
      scope :canceling, -> { with_status(:canceling) }
      scope :canceled, -> { with_status(:canceled) }
      scope :skipped, -> { with_status(:skipped) }
      scope :manual, -> { with_status(:manual) }
      scope :scheduled, -> { with_status(:scheduled) }
      scope :alive, -> { with_status(*ALIVE_STATUSES) }
      scope :created_or_pending, -> { with_status(:created, :pending) }
      scope :running_or_pending, -> { with_status(:running, :pending) }
      scope :executing, -> { with_status(*EXECUTING_STATUSES) }
      scope :finished, -> { with_status(:success, :failed, :canceled) }
      scope :failed_or_canceled, -> { with_status(:failed, :canceled, :canceling) }
      scope :complete, -> { with_status(completed_statuses) }
      scope :incomplete, -> { without_statuses(completed_statuses) }
      scope :complete_or_manual, -> { with_status(completed_with_manual_statuses) }
      scope :waiting_for_resource_or_upcoming, -> { with_status(:created, :scheduled, :waiting_for_resource) }

      scope :cancelable, -> do
        where(status: klass::CANCELABLE_STATUSES)
      end

      scope :without_statuses, ->(names) do
        with_status(all_state_names - names.to_a)
      end
    end

    def started?
      STARTED_STATUSES.include?(status) && !!started_at
    end

    def active?
      ACTIVE_STATUSES.include?(status)
    end

    def complete?
      COMPLETED_STATUSES.include?(status)
    end

    def complete_or_manual?
      COMPLETED_WITH_MANUAL_STATUSES.include?(status)
    end

    def incomplete?
      COMPLETED_STATUSES.exclude?(status)
    end

    def blocked?
      BLOCKED_STATUS.include?(status)
    end

    private

    def calculate_duration(start_time, end_time)
      return unless start_time

      (end_time || Time.current) - start_time
    end
  end
end
