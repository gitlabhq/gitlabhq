# frozen_string_literal: true

module API
  module Entities
    module BulkImports
      class EntityFailure < Grape::Entity
        expose :relation
        expose :pipeline_step, as: :step
        expose :exception_message do |failure|
          ::Projects::ImportErrorFilter.filter_message(failure.exception_message.truncate(72))
        end
        expose :exception_class
        expose :correlation_id_value
        expose :created_at
        expose :pipeline_class
        expose :pipeline_step
      end
    end
  end
end
