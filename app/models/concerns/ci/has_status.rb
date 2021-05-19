# frozen_string_literal: true

module Ci
  module HasStatus
    extend ActiveSupport::Concern

    DEFAULT_STATUS = 'created'
    BLOCKED_STATUS = %w[manual scheduled].freeze
    AVAILABLE_STATUSES = %w[created waiting_for_resource preparing pending running success failed canceled skipped manual scheduled].freeze
    STARTED_STATUSES = %w[running success failed skipped manual scheduled].freeze
    ACTIVE_STATUSES = %w[waiting_for_resource preparing pending running].freeze
    COMPLETED_STATUSES = %w[success failed canceled skipped].freeze
    ORDERED_STATUSES = %w[failed preparing pending running waiting_for_resource manual scheduled canceled success skipped created].freeze
    PASSED_WITH_WARNINGS_STATUSES = %w[failed canceled].to_set.freeze
    EXCLUDE_IGNORED_STATUSES = %w[manual failed canceled].to_set.freeze
    STATUSES_ENUM = { created: 0, pending: 1, running: 2, success: 3,
                      failed: 4, canceled: 5, skipped: 6, manual: 7,
                      scheduled: 8, preparing: 9, waiting_for_resource: 10 }.freeze
    STATUSES_DESCRIPTION = {
      created: 'Pipeline has been created',
      waiting_for_resource: 'A resource (for example, a runner) that the pipeline requires to run is unavailable',
      preparing: 'Pipeline is preparing to run',
      pending: 'Pipeline has not started running yet',
      running: 'Pipeline is running',
      failed: 'At least one stage of the pipeline failed',
      success: 'Pipeline completed successfully',
      canceled: 'Pipeline was canceled before completion',
      skipped: 'Pipeline was skipped',
      manual: 'Pipeline needs to be manually started',
      scheduled: 'Pipeline is scheduled to run'
    }.freeze

    UnknownStatusError = Class.new(StandardError)

    class_methods do
      # The parameter `project` is only used for the feature flag check, and will be removed with
      # https://gitlab.com/gitlab-org/gitlab/-/issues/321972
      def composite_status(project: nil)
        Gitlab::Ci::Status::Composite
          .new(all, with_allow_failure: columns_hash.key?('allow_failure'), project: project)
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

    def calculate_duration(start_time, end_time)
      return unless start_time

      (end_time || Time.current) - start_time
    end
  end
end
