# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundOperation
      class WorkerCellLocal < SharedModel
        include CommonWorker
        include Queueable

        self.table_name = :background_operation_workers_cell_local

        ignore_column :next_min_cursor, remove_with: '18.8', remove_after: '2026-01-15'

        has_many :jobs,
          ->(worker) { where(worker_partition: worker.partition) },
          class_name: 'Gitlab::Database::BackgroundOperation::JobCellLocal',
          foreign_key: :worker_id,
          inverse_of: :worker,
          partition_foreign_key: :worker_partition

        has_one :last_job, -> { order(max_cursor: :desc, created_at: :desc) },
          class_name: 'Gitlab::Database::BackgroundOperation::JobCellLocal',
          inverse_of: :worker,
          partition_foreign_key: :worker_partition
      end
    end
  end
end
