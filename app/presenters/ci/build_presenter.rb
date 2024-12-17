# frozen_string_literal: true

module Ci
  class BuildPresenter < ProcessablePresenter
    presents ::Ci::Build, as: :build

    def status_title(status = detailed_status)
      if auto_canceled?
        "Job is redundant and is auto-canceled by Pipeline ##{auto_canceled_by_id}"
      else
        tooltip_for_badge(status)
      end
    end

    def trigger_variables
      return [] unless trigger_request

      @trigger_variables ||=
        if pipeline.variables.any?
          pipeline.variables.map(&:to_hash_variable)
        else
          trigger_request.user_variables
        end
    end

    def execute_in
      scheduled? && scheduled_at && [0, scheduled_at - Time.now].max
    end

    def failure_message
      callout_failure_message if build.failed?
    end

    private

    def tooltip_for_badge(status)
      status.badge_tooltip.capitalize
    end

    def detailed_status
      @detailed_status ||= build.detailed_status(user)
    end
  end
end

Ci::BuildPresenter.prepend_mod_with('Ci::BuildPresenter')
