# frozen_string_literal: true

module API
  module Entities
    module Ci
      class Variable < Grape::Entity
        expose :variable_type, documentation: { type: 'String', example: 'env_var' }
        expose :key, documentation: { type: 'String', example: 'TEST_VARIABLE_1' }
        expose :value, documentation: { type: 'String', example: 'TEST_1' } do |variable, _options|
          if variable.respond_to?(:hidden)
            ::Ci::VariableValue.new(variable).evaluate
          else
            variable.value
          end
        end
        expose :hidden?, as: :hidden, documentation: { type: 'Boolean' }, if: ->(variable, _) do
          variable.respond_to?(:hidden?)
        end
        expose :protected?, as: :protected, if: ->(entity, _) { entity.respond_to?(:protected?) },
          documentation: { type: 'Boolean' }
        expose :masked?, as: :masked, if: ->(entity, _) { entity.respond_to?(:masked?) },
          documentation: { type: 'Boolean' }
        expose :raw?, as: :raw, if: ->(entity, _) { entity.respond_to?(:raw?) }, documentation: { type: 'Boolean' }
        expose :environment_scope, if: ->(entity, _) { entity.respond_to?(:environment_scope) },
          documentation: { type: 'String', example: '*' }
        expose :description, if: ->(entity, _) { entity.respond_to?(:description) },
          documentation: { type: 'String', example: 'This variable is being used for ...' }
      end
    end
  end
end
