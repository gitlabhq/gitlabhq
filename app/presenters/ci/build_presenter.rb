# frozen_string_literal: true

module Ci
  class BuildPresenter < ProcessablePresenter
    def erased_by_user?
      # Build can be erased through API, therefore it does not have
      # `erased_by` user assigned in that case.
      erased? && erased_by
    end

    def erased_by_name
      erased_by.name if erased_by_user?
    end

    def status_title
      if auto_canceled?
        "Job is redundant and is auto-canceled by Pipeline ##{auto_canceled_by_id}"
      else
        tooltip_for_badge
      end
    end

    def trigger_variables
      return [] unless trigger_request

      @trigger_variables ||=
        if pipeline.variables.any?
          pipeline.variables.map(&:to_runner_variable)
        else
          trigger_request.user_variables
        end
    end

    def tooltip_message
      "#{subject.name} - #{detailed_status.status_tooltip}"
    end

    def execute_in
      scheduled? && scheduled_at && [0, scheduled_at - Time.now].max
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
