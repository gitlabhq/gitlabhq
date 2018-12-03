# frozen_string_literal: true

class TriggerVariableEntity < Grape::Entity
  include RequestAwareEntity

  expose :key, :public
  expose :value, if: ->(_, _) { request.project.team.maintainer?(request.current_user) }
end
