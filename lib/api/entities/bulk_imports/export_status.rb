# frozen_string_literal: true

module API
  module Entities
    module BulkImports
      class ExportStatus < Grape::Entity
        expose :relation, documentation: { type: 'string', example: 'issues' }
        expose :status, documentation: { type: 'string', example: 'started', values: %w[started finished failed] }
        expose :error, documentation: { type: 'string', example: 'Error message' }
        expose :updated_at, documentation: { type: 'dateTime', example: '2012-05-28T04:42:42-07:00' }
      end
    end
  end
end
