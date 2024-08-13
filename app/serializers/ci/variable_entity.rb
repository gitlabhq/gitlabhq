# frozen_string_literal: true

module Ci
  class VariableEntity < Ci::BasicVariableEntity
    expose :environment_scope
    expose :hidden?, as: :hidden
  end
end
