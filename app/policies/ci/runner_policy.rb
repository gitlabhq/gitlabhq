# frozen_string_literal: true

module Ci
  class RunnerPolicy < BasePolicy
    with_options scope: :subject, score: 0
    condition(:locked, scope: :subject) { @subject.locked? }

    condition(:owned_runner) do
      @user.owns_runner?(@subject)
    end

    condition(:belongs_to_multiple_projects) do
      @subject.belongs_to_more_than_one_project?
    end

    rule { anonymous }.prevent_all

    rule { admin }.policy do
      enable :read_builds
    end

    rule { admin | owned_runner }.policy do
      enable :assign_runner
      enable :read_runner
      enable :update_runner
      enable :delete_runner
    end

    rule { ~admin & belongs_to_multiple_projects }.prevent :delete_runner

    rule { ~admin & locked }.prevent :assign_runner
  end
end

Ci::RunnerPolicy.prepend_mod_with('Ci::RunnerPolicy')
