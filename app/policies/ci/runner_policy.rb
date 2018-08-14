# frozen_string_literal: true

module Ci
  class RunnerPolicy < BasePolicy
    with_options scope: :subject, score: 0
    condition(:locked, scope: :subject) { @subject.locked? }

    condition(:owned_runner) { @user.ci_owned_runners.exists?(@subject.id) }

    rule { anonymous }.prevent_all

    rule { admin | owned_runner }.policy do
      enable :assign_runner
      enable :read_runner
      enable :update_runner
      enable :delete_runner
    end

    rule { ~admin & locked }.prevent :assign_runner
  end
end
