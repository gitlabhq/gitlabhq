# frozen_string_literal: true

module Ci
  class RunnerManagerPolicy < BasePolicy
    condition(:can_read_runner) do
      can?(:read_runner, @subject.runner)
    end

    rule { anonymous }.prevent_all

    rule { can_read_runner }.policy do
      enable :read_builds
      enable :read_runner_manager
    end
  end
end
