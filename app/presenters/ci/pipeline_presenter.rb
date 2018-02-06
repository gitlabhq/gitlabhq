module Ci
  class PipelinePresenter < Gitlab::View::Presenter::Delegated
    FAILURE_REASONS = {
      config_error: 'CI/CD YAML configuration error!'
    }.freeze

    presents :pipeline

    def failure_reason
      return unless pipeline.failure_reason?

      FAILURE_REASONS[pipeline.failure_reason.to_sym] ||
        pipeline.failure_reason
    end

    def status_title
      if auto_canceled?
        "Pipeline is redundant and is auto-canceled by Pipeline ##{auto_canceled_by_id}"
      end
    end
  end
end
