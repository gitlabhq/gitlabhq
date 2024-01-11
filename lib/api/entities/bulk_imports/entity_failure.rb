# frozen_string_literal: true

module API
  module Entities
    module BulkImports
      class EntityFailure < Grape::Entity
        expose :relation, documentation: { type: 'string', example: 'label' }
        expose :exception_message, documentation: { type: 'string', example: 'error message' } do |failure|
          ::Projects::ImportErrorFilter.filter_message(failure.exception_message).truncate(255)
        end
        expose :exception_class, documentation: { type: 'string', example: 'Exception' }
        expose :correlation_id_value, documentation: { type: 'string', example: 'dfcf583058ed4508e4c7c617bd7f0edd' }
        expose :source_url, documentation: { type: 'string', example: 'https://source.gitlab.com/group/-/epics/1' }
        expose :source_title, documentation: { type: 'string', example: 'title' }
      end
    end
  end
end
