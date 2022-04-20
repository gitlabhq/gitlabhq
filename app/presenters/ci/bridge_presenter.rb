# frozen_string_literal: true

module Ci
  class BridgePresenter < ProcessablePresenter
    presents ::Ci::Bridge, as: :bridge

    delegator_override :detailed_status
    def detailed_status
      @detailed_status ||= bridge.detailed_status(user)
    end
  end
end
