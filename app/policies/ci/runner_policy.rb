module Ci
  class RunnerPolicy < BasePolicy
    with_options scope: :subject, score: 0
    condition(:locked, scope: :subject) { @subject.locked? }

    condition(:authorized_runner) { @user.ci_authorized_runners.exists?(@subject.id) }

    rule { anonymous }.prevent_all
    rule { admin | authorized_runner }.enable :assign_runner
    rule { admin | authorized_runner }.enable :read_runner
    rule { admin | authorized_runner }.enable :update_runner
    rule { admin | authorized_runner }.enable :delete_runner
    rule { admin | authorized_runner }.enable :list_runner_jobs
    rule { ~admin & locked }.prevent :assign_runner
  end
end
