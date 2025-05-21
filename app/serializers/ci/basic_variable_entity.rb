# frozen_string_literal: true

module Ci
  class BasicVariableEntity < Grape::Entity
    expose :id
    expose :key
    expose :value do |variable, _options|
      if variable.respond_to?(:hidden)
        ::Ci::VariableValue.new(variable).evaluate
      else
        variable.value
      end
    end
    expose :description
    expose :variable_type

    expose :protected?, as: :protected
    expose :masked?, as: :masked
    expose :raw?, as: :raw
  end
end
