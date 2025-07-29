# frozen_string_literal: true

module Ci
  class RunnerProjectPolicy < BasePolicy
    condition(:locked, scope: :subject) { @subject.runner.locked? }

    condition(:assigned_to_owner_project, scope: :subject) { @subject.project == @subject.runner.owner }

    condition(:can_admin_project_runners, score: 2) do
      Ability.allowed?(@user, :admin_runners, @subject.project)
    end

    rule { anonymous }.prevent_all

    rule { can_admin_project_runners }.enable :unassign_runner

    rule { ~admin & locked }.prevent :unassign_runner

    rule { assigned_to_owner_project }.prevent :unassign_runner
  end
end

Ci::RunnerProjectPolicy.prepend_mod
