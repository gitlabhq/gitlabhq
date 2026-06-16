# frozen_string_literal: true

module Ci
  class InstanceVariableEntity < Ci::BasicVariableEntity
    expose :hidden?, as: :hidden
  end
end
