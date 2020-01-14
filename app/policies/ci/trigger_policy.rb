# frozen_string_literal: true

module Ci
  class TriggerPolicy < BasePolicy
    delegate { @subject.project }

    with_options scope: :subject, score: 0

    with_score 0
    condition(:is_owner) { @user && @subject.owner_id == @user.id }

    rule { ~can?(:admin_build) }.prevent :admin_trigger
    rule { is_owner }.enable :admin_trigger

    rule { can?(:admin_build) }.enable :manage_trigger
  end
end
