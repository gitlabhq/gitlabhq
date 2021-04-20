# frozen_string_literal: true

module Ci
  class GroupVariableEntity < Ci::BasicVariableEntity
    expose :environment_scope
  end
end
