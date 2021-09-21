# frozen_string_literal: true

module Ci
  class LegacyStagePresenter < Gitlab::View::Presenter::Delegated
    presents ::Ci::LegacyStage, as: :legacy_stage

    def latest_ordered_statuses
      preload_statuses(legacy_stage.statuses.latest_ordered)
    end

    def retried_ordered_statuses
      preload_statuses(legacy_stage.statuses.retried_ordered)
    end

    private

    def preload_statuses(statuses)
      Preloaders::CommitStatusPreloader.new(statuses).execute(Ci::StagePresenter::PRELOADED_RELATIONS)

      statuses
    end
  end
end
