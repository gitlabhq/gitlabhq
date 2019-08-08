# frozen_string_literal: true

class VariableEntity < Grape::Entity
  expose :id
  expose :key
  expose :value

  expose :protected?, as: :protected
  expose :masked?, as: :masked
  expose :environment_scope
end
