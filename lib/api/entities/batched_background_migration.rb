# frozen_string_literal: true

module API
  module Entities
    class BatchedBackgroundMigration < Grape::Entity
      expose :id, documentation: { type: 'String', example: "1234" }
      expose :job_class_name, documentation: { type: 'String', example: "CopyColumnUsingBackgroundMigrationJob" }
      expose :table_name, documentation: { type: 'String', example: "events" }
      expose :column_name, documentation: { type: 'String', example: "id" }
      expose :status_name, as: :status, override: true, documentation: { type: 'String', example: "active" }
      expose :progress, documentation: { type: 'Float', example: 50 }
      expose :created_at, documentation: { type: 'DateTime', example: "2022-11-28T16:26:39+02:00" }
      expose :estimated_time_remaining, documentation: { type: 'String', example: '1 day' }
    end
  end
end
