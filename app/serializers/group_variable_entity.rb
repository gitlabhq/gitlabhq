# frozen_string_literal: true

class GroupVariableEntity < Grape::Entity
  expose :id
  expose :key
  expose :value

  expose :protected?, as: :protected
end
