# frozen_string_literal: true

class TriggerVariableEntity < Grape::Entity
  include RequestAwareEntity

  expose :key, :value, :public
end
