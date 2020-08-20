# frozen_string_literal: true

module API
  module Entities
    module Ci
      class Variable < Grape::Entity
        expose :variable_type, :key, :value
        expose :protected?, as: :protected, if: -> (entity, _) { entity.respond_to?(:protected?) }
        expose :masked?, as: :masked, if: -> (entity, _) { entity.respond_to?(:masked?) }
        expose :environment_scope, if: -> (entity, _) { entity.respond_to?(:environment_scope) }
      end
    end
  end
end
