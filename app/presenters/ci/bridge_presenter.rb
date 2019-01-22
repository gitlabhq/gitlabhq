# frozen_string_literal: true

module Ci
  class BridgePresenter < CommitStatusPresenter
    def status_title
      tooltip_for_badge
    end

    def tooltip_message
      "#{subject.name} - #{detailed_status.status_tooltip}"
    end

    private

    def tooltip_for_badge
      detailed_status.badge_tooltip.capitalize
    end

    def detailed_status
      @detailed_status ||= subject.detailed_status(user)
    end
  end
end
