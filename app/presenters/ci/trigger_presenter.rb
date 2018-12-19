# frozen_string_literal: true

module Ci
  class TriggerPresenter < Gitlab::View::Presenter::Delegated
    presents :trigger

    def has_token_exposed?
      can?(current_user, :admin_trigger, trigger)
    end

    def token
      if has_token_exposed?
        trigger.token
      else
        trigger.short_token
      end
    end
  end
end
