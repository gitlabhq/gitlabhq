# frozen_string_literal: true

module Ci
  class TriggerEntity < Grape::Entity
    include Gitlab::Routing
    include Gitlab::Allowable

    expose :id
    expose :description
    expose :owner, using: UserEntity
    expose :last_used
    expose :expires_at

    expose :token do |trigger|
      can_admin_trigger?(trigger) ? trigger.token : trigger.short_token
    end

    expose :has_token_exposed do |trigger|
      can_admin_trigger?(trigger)
    end

    expose :can_access_project do |trigger|
      trigger.can_access_project?
    end

    expose :project_trigger_path, if: ->(trigger) { can_manage_trigger?(trigger) } do |trigger|
      project_trigger_path(options[:project], trigger)
    end

    private

    def can_manage_trigger?(trigger)
      can?(options[:current_user], :manage_trigger, trigger)
    end

    def can_admin_trigger?(trigger)
      can?(options[:current_user], :admin_trigger, trigger)
    end
  end
end
