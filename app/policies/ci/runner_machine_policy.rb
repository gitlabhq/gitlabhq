# frozen_string_literal: true

module Ci
  class RunnerMachinePolicy < BasePolicy
    with_options scope: :subject, score: 0

    condition(:can_read_runner, scope: :subject) do
      can?(:read_runner, @subject.runner)
    end

    rule { anonymous }.prevent_all

    rule { can_read_runner }.policy do
      enable :read_builds
      enable :read_runner_machine
    end
  end
end
