# frozen_string_literal: true

module API
  module Entities
    module BulkImports
      class ExportStatus < Grape::Entity
        expose :relation, documentation: { type: 'String', example: 'issues' }
        expose :status,
          documentation: { type: 'String', example: 'started', values: %w[pending started finished failed] }
        expose :error, documentation: { type: 'String', example: 'Error message' }
        expose :updated_at, documentation: { type: 'DateTime', example: '2012-05-28T04:42:42-07:00' }
        expose :batched, documentation: { type: 'Boolean', example: true }
        expose :batches_count, documentation: { type: 'Integer', example: 2 }
        expose :total_objects_count, documentation: { type: 'Integer', example: 100 }
        expose :batches, if: ->(export, _options) { export.batched? }, using: ExportBatchStatus
      end
    end
  end
end
