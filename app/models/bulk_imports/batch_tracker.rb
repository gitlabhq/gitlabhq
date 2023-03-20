# frozen_string_literal: true

module BulkImports
  class BatchTracker < ApplicationRecord
    self.table_name = 'bulk_import_batch_trackers'

    belongs_to :tracker, class_name: 'BulkImports::Tracker'

    validates :batch_number, presence: true, uniqueness: { scope: :tracker_id }

    state_machine :status, initial: :created do
      state :created, value: 0
      state :started, value: 1
      state :finished, value: 2
      state :timeout, value: 3
      state :failed, value: -1
      state :skipped, value: -2

      event :start do
        transition created: :started
      end

      event :retry do
        transition started: :created
      end

      event :finish do
        transition started: :finished
        transition failed: :failed
        transition skipped: :skipped
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
    end
  end
end
