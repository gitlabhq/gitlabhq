module Ci
  class TriggerPolicy < BasePolicy
    def rules
      delegate! @subject.project

      if can?(:admin_build)
        can! :admin_trigger if @subject.owner.blank? ||
            @subject.owner == @user
        can! :manage_trigger
      end
    end
  end
end
