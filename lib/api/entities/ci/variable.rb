# frozen_string_literal: true

module API
  module Entities
    module Ci
      class Variable < Grape::Entity
        expose :variable_type, documentation: { type: 'string', example: 'env_var' }
        expose :key, documentation: { type: 'string', example: 'TEST_VARIABLE_1' }
        expose :value, documentation: { type: 'string', example: 'TEST_1' }
        expose :protected?, as: :protected, if: -> (entity, _) { entity.respond_to?(:protected?) },
                            documentation: { type: 'boolean' }
        expose :masked?, as: :masked, if: -> (entity, _) { entity.respond_to?(:masked?) },
                         documentation: { type: 'boolean' }
        expose :raw?, as: :raw, if: -> (entity, _) { entity.respond_to?(:raw?) }, documentation: { type: 'boolean' }
        expose :environment_scope, if: -> (entity, _) { entity.respond_to?(:environment_scope) },
                                   documentation: { type: 'string', example: '*' }
      end
    end
  end
end
