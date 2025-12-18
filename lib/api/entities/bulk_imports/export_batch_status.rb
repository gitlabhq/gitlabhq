# frozen_string_literal: true

module API
  module Entities
    module BulkImports
      class ExportBatchStatus < Grape::Entity
        expose :status, documentation: { type: 'String', example: 'started', values: %w[started finished failed] }
        expose :batch_number, documentation: { type: 'Integer', example: 1 }
        expose :objects_count, documentation: { type: 'Integer', example: 100 }
        expose :error, documentation: { type: 'String', example: 'Error message' }
        expose :updated_at, documentation: { type: 'DateTime', example: '2012-05-28T04:42:42-07:00' }
      end
    end
  end
end
