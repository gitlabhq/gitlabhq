# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundOperation
      class WorkerCellLocal < SharedModel
        include CommonWorker
        include Queueable
        include Observable

        WORKER_TYPE = :cell_local

        ALLOWED_ENQUEUER = 'Database::BackgroundOperation::CronEnqueueWorker'

        def self.allowed_enqueuer
          ALLOWED_ENQUEUER
        end

        self.table_name = :background_operation_workers_cell_local

        has_many :jobs,
          class_name: 'Gitlab::Database::BackgroundOperation::JobCellLocal',
          inverse_of: :worker,
          foreign_key: [:worker_id, :worker_partition]

        has_one :last_job, -> { order(max_cursor: :desc, created_at: :desc) },
          class_name: 'Gitlab::Database::BackgroundOperation::JobCellLocal',
          inverse_of: :worker,
          foreign_key: [:worker_id, :worker_partition]
      end
    end
  end
end
