module Ci
  class BuildPresenter < Gitlab::View::Presenter::Delegated
    CALLOUT_FAILURE_MESSAGES = {
      unknown_failure: 'There is an unknown failure, please try again',
      script_failure: 'There has been a script failure. Check the job log for more information',
      api_failure: 'There has been an API failure, please try again',
      stuck_or_timeout_failure: 'There has been a timeout failure or the job got stuck. Check your timeout limits or try again',
      runner_system_failure: 'There has been a runner system failure, please try again',
      missing_dependency_failure: 'There has been a missing dependency failure, check the job log for more information'
    }.freeze

    presents :build

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

    def callout_failure_message
      CALLOUT_FAILURE_MESSAGES[failure_reason.to_sym]
    end

    def recoverable?
      failed? && !unrecoverable?
    end

    private

    def tooltip_for_badge
      detailed_status.badge_tooltip.capitalize
    end

    def detailed_status
      @detailed_status ||= subject.detailed_status(user)
    end

    def unrecoverable?
      script_failure? || missing_dependency_failure?
    end
  end
end
