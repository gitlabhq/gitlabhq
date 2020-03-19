# frozen_string_literal: true

class GroupVariableEntity < Grape::Entity
  expose :id
  expose :key
  expose :value
  expose :variable_type

  expose :protected?, as: :protected
  expose :masked?, as: :masked
end
