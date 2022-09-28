# frozen_string_literal: true

module API
  module Entities
    module BulkImports
      class EntityFailure < Grape::Entity
        expose :exception_message do |failure|
          ::Projects::ImportErrorFilter.filter_message(failure.exception_message.truncate(72))
        end
        expose :exception_class
        expose :pipeline_class
        expose :pipeline_step
        expose :correlation_id_value
        expose :created_at
      end
    end
  end
end
