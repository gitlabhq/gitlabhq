# frozen_string_literal: true

module Ci
  class TriggerPresenter < Gitlab::View::Presenter::Delegated
    presents ::Ci::Trigger, as: :trigger

    def has_token_exposed?
      can?(current_user, :admin_trigger, trigger)
    end

    delegator_override :token
    def token
      if has_token_exposed?
        trigger.token
      else
        trigger.short_token
      end
    end
  end
end
