# frozen_string_literal: true

module Ci
  class TriggerPolicy < BasePolicy
    delegate { @subject.project }

    with_options scope: :subject, score: 0

    with_score 0
    condition(:is_owner) { @user && @subject.owner_id == @user.id }

    rule { ~can?(:manage_trigger) }.prevent :admin_trigger
    rule { admin | is_owner }.enable :admin_trigger
  end
end
