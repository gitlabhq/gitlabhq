module Ci
  class RunnerPolicy < BasePolicy
    def rules
      return unless @user

      can! :assign_runner if @user.is_admin?

      return if @subject.is_shared? || @subject.locked?

      can! :assign_runner if @user.ci_authorized_runners.include?(@subject)
    end
  end
end
