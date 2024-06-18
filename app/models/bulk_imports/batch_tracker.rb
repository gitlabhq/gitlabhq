# frozen_string_literal: true

module BulkImports
  class BatchTracker < ApplicationRecord
    self.table_name = 'bulk_import_batch_trackers'

    belongs_to :tracker, class_name: 'BulkImports::Tracker'

    validates :batch_number, presence: true, uniqueness: { scope: :tracker_id }

    IN_PROGRESS_STATES = %i[created started].freeze

    scope :by_last_updated, -> { order(updated_at: :desc) }
    scope :in_progress, -> { with_status(IN_PROGRESS_STATES) }

    # rubocop: disable Database/AvoidUsingPluckWithoutLimit -- We should use this method only when scoped to a tracker.
    # Batches are self-limiting per tracker based on the amount of data being imported.
    def self.pluck_batch_numbers
      pluck(:batch_number)
    end
    # rubocop: enable Database/AvoidUsingPluckWithoutLimit

    state_machine :status, initial: :created do
      state :created, value: 0
      state :started, value: 1
      state :finished, value: 2
      state :timeout, value: 3
      state :failed, value: -1
      state :skipped, value: -2
      state :canceled, value: -3

      event :start do
        transition created: :started
        # To avoid errors when re-starting a pipeline in case of network errors
        transition started: :started
      end

      event :retry do
        transition started: :created
      end

      event :finish do
        transition any => :finished
      end

      event :skip do
        transition any => :skipped
      end

      event :fail_op do
        transition any => :failed
      end

      event :cleanup_stale do
        transition [:created, :started] => :timeout
      end

      event :cancel do
        transition any => :canceled
      end
    end
  end
end
