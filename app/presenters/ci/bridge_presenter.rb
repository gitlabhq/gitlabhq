# frozen_string_literal: true

module Ci
  class BridgePresenter < ProcessablePresenter
    def detailed_status
      @detailed_status ||= subject.detailed_status(user)
    end
  end
end
