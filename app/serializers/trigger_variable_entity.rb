# frozen_string_literal: true

class TriggerVariableEntity < Grape::Entity
  include RequestAwareEntity

  expose :key, :public
  expose :value, if: ->(_, _) { can?(request.current_user, :admin_build, request.project) }
end
