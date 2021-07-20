# frozen_string_literal: true

module API
  module Entities
    module BulkImports
      class EntityFailure < Grape::Entity
        expose :pipeline_class
        expose :pipeline_step
        expose :exception_class
        expose :correlation_id_value
        expose :created_at
      end
    end
  end
end
