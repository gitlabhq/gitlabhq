# frozen_string_literal: true

module Ci
  class StagePresenter < Gitlab::View::Presenter::Delegated
    presents ::Ci::Stage, as: :stage

    PRELOADED_RELATIONS = [:pipeline, :metadata, :tags, :job_artifacts_archive, :downstream_pipeline].freeze

    def latest_ordered_statuses
      preload_statuses(stage.statuses.latest_ordered)
    end

    def retried_ordered_statuses
      preload_statuses(stage.statuses.retried_ordered)
    end

    private

    def preload_statuses(statuses)
      Preloaders::CommitStatusPreloader.new(statuses).execute(PRELOADED_RELATIONS)

      statuses
    end
  end
end
