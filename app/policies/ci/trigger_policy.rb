module Ci
  class TriggerPolicy < BasePolicy
    delegate { @subject.project }

    condition(:unowned, scope: :subject) { @subject.owner.blank? }
    condition(:is_owner) { @user && @subject.owner == @user }

    rule { ~can?(:admin_build) }.prevent :admin_trigger
    rule { unowned | is_owner }.enable :admin_trigger

    rule { can?(:admin_build) }.enable :manage_trigger
  end
end
