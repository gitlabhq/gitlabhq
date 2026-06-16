# frozen_string_literal: true

module API
  module Entities
    class BatchedBackgroundOperation < Grape::Entity
      expose :external_id, as: :id, documentation: { type: 'String', example: '<cluster>:<partition_id>:<id/uuid>' }
      expose :partition, documentation: { type: 'Integer', example: 1 }
      expose :job_class_name, documentation: { type: 'String', example: 'UsersDeleteUnconfirmedSecondaryEmails' }
      expose :table_name, documentation: { type: 'String', example: 'users' }
      expose :column_name, documentation: { type: 'String', example: 'id' }
      expose :status_name, as: :status, override: true, documentation: { type: 'String', example: 'active' }
      expose :created_at, documentation: { type: 'DateTime', example: '2025-05-15T10:00:00Z' }
      expose :started_at, documentation: { type: 'DateTime', example: '2025-05-15T10:05:00Z' }
      expose :finished_at, documentation: { type: 'DateTime', example: '2025-05-15T11:00:00Z' }
      expose :on_hold_until, documentation: { type: 'DateTime', example: '2025-05-15T10:15:00Z' }
    end
  end
end
