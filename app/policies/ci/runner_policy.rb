module Ci
  class RunnerPolicy < BasePolicy
    with_options scope: :subject, score: 0
    condition(:shared) { @subject.is_shared? }

    with_options scope: :subject, score: 0
    condition(:locked, scope: :subject) { @subject.locked? }

    condition(:authorized_runner) { @user.ci_authorized_runners.include?(@subject) }

    rule { anonymous }.prevent_all
    rule { admin | authorized_runner }.enable :assign_runner
    rule { ~admin & shared }.prevent :assign_runner
    rule { ~admin & locked }.prevent :assign_runner
  end
end
