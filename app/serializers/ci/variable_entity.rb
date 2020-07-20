# frozen_string_literal: true

module Ci
  class VariableEntity < Ci::BasicVariableEntity
    expose :environment_scope
  end
end
