# frozen_string_literal: true

module Ci
  class TriggersFinder
    def initialize(current_user, project)
      @current_user = current_user
      @project = project
    end

    def execute
      return Ci::Trigger.none unless Ability.allowed?(@current_user, :admin_build, @project)

      @project.triggers
    end
  end
end
