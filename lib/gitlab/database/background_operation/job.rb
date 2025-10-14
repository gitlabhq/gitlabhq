# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundOperation
      class Job < SharedModel
        include CommonJob

        self.table_name = :background_operation_jobs

        belongs_to :worker,
          class_name: 'Gitlab::Database::BackgroundOperation::Worker',
          partition_foreign_key: :worker_partition,
          inverse_of: :jobs

        belongs_to :organization
      end
    end
  end
end
