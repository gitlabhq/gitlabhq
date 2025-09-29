# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundOperation
      class JobCellLocal < SharedModel
        include CommonJob

        self.table_name = :background_operation_jobs_cell_local

        belongs_to :worker,
          class_name: 'Gitlab::Database::BackgroundOperation::WorkerCellLocal',
          partition_foreign_key: :worker_partition,
          inverse_of: :jobs
      end
    end
  end
end
