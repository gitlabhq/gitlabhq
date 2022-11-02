# frozen_string_literal: true

module API
  module Entities
    module BulkImports
      class EntityFailure < Grape::Entity
        expose :relation, documentation: { type: 'string', example: 'group' }
        expose :pipeline_step, as: :step, documentation: { type: 'string', example: 'extractor' }
        expose :exception_message, documentation: { type: 'string', example: 'error message' } do |failure|
          ::Projects::ImportErrorFilter.filter_message(failure.exception_message.truncate(72))
        end
        expose :exception_class, documentation: { type: 'string', example: 'Exception' }
        expose :correlation_id_value, documentation: { type: 'string', example: 'dfcf583058ed4508e4c7c617bd7f0edd' }
        expose :created_at, documentation: { type: 'dateTime', example: '2012-05-28T04:42:42-07:00' }
        expose :pipeline_class, documentation: {
          type: 'string', example: 'BulkImports::Groups::Pipelines::GroupPipeline'
        }
        expose :pipeline_step, documentation: { type: 'string', example: 'extractor' }
      end
    end
  end
end
