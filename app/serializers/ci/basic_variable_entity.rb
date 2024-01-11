# frozen_string_literal: true

module Ci
  class BasicVariableEntity < Grape::Entity
    expose :id
    expose :key
    expose :value
    expose :description
    expose :variable_type

    expose :protected?, as: :protected
    expose :masked?, as: :masked
    expose :raw?, as: :raw
  end
end
