# frozen_string_literal: true

module API
  module Entities
    class BatchedBackgroundMigration < Grape::Entity
      expose :id, documentation: { type: :string, example: "1234" }
      expose :job_class_name, documentation: { type: :string, example: "CopyColumnUsingBackgroundMigrationJob" }
      expose :table_name, documentation: { type: :string, example: "events" }
      expose :column_name, documentation: { type: :string, example: "id" }
      expose :status_name, as: :status, override: true, documentation: { type: :string, example: "active" }
      expose :progress, documentation: { type: :float, example: 50 }
      expose :created_at, documentation: { type: :dateTime, example: "2022-11-28T16:26:39+02:00" }
    end
  end
end
