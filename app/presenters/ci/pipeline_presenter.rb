# frozen_string_literal: true

module Ci
  class PipelinePresenter < Gitlab::View::Presenter::Delegated
    include Gitlab::Utils::StrongMemoize

    # We use a class method here instead of a constant, allowing EE to redefine
    # the returned `Hash` more easily.
    def self.failure_reasons
      { config_error: 'CI/CD YAML configuration error!' }
    end

    presents :pipeline

    def failed_builds
      return [] unless can?(current_user, :read_build, pipeline)

      strong_memoize(:failed_builds) do
        pipeline.builds.latest.failed
      end
    end

    def failure_reason
      return unless pipeline.failure_reason?

      self.class.failure_reasons[pipeline.failure_reason.to_sym] ||
        pipeline.failure_reason
    end

    def status_title
      if auto_canceled?
        "Pipeline is redundant and is auto-canceled by Pipeline ##{auto_canceled_by_id}"
      end
    end
  end
end
