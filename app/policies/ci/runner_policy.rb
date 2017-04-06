module Ci
  class RunnerPolicy < BasePolicy
    rule { anonymous }.prevent_all

    condition(:shared, scope: :subject) { @subject.is_shared? }
    condition(:locked, scope: :subject) { @subject.locked? }
    condition(:authorized_runner) { @user.ci_authorized_runners.include?(@subject) }

    rule { admin | authorized_runner }.enable :assign_runner
    rule { ~admin & shared }.prevent :assign_runner
    rule { ~admin & locked }.prevent :assign_runner
  end
end
