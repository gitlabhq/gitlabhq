# frozen_string_literal: true

module Ci
  class FreezePeriodsFinder
    def initialize(project, current_user = nil)
      @project = project
      @current_user = current_user
    end

    def execute
      return Ci::FreezePeriod.none unless Ability.allowed?(@current_user, :read_freeze_period, @project)

      @project.freeze_periods
    end
  end
end
