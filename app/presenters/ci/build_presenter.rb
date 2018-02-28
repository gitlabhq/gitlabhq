module Ci
  class BuildPresenter < Gitlab::View::Presenter::Delegated

    TIMEOUT_SOURCES = {
        unknown_timeout_source: nil,
        project_timeout_source: 'project',
        runner_timeout_source: 'runner'
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
      end
    end

    def timeout_source
      return unless build.timeout_source?

      TIMEOUT_SOURCES[build.timeout_source.to_sym] ||
          build.timeout_source
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
  end
end
