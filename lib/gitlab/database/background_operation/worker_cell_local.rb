# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundOperation
      class WorkerCellLocal < SharedModel
        include CommonWorker

        self.table_name = :background_operation_workers_cell_local

        has_many :jobs,
          ->(worker) { where(worker_partition: worker.partition) },
          class_name: 'Gitlab::Database::BackgroundOperation::JobCellLocal',
          foreign_key: :worker_id,
          inverse_of: :worker,
          partition_foreign_key: :worker_partition
      end
    end
  end
end
