# frozen_string_literal: true

module API
  module Entities
    module BulkImports
      class ExportStatus < Grape::Entity
        expose :relation, documentation: { type: 'string', example: 'issues' }
        expose :status, documentation: { type: 'string', example: 'started', values: %w[started finished failed] }
        expose :error, documentation: { type: 'string', example: 'Error message' }
        expose :updated_at, documentation: { type: 'dateTime', example: '2012-05-28T04:42:42-07:00' }
        expose :batched, documentation: { type: 'boolean', example: true }
        expose :batches_count, documentation: { type: 'integer', example: 2 }
        expose :total_objects_count, documentation: { type: 'integer', example: 100 }
        expose :batches, if: ->(export, _options) { export.batched? }, using: ExportBatchStatus
      end
    end
  end
end
