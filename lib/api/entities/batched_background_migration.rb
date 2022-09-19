# frozen_string_literal: true

module API
  module Entities
    class BatchedBackgroundMigration < Grape::Entity
      expose :id
      expose :job_class_name
      expose :table_name
      expose :status, &:status_name
      expose :progress
      expose :created_at
    end
  end
end
