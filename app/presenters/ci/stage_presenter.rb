# frozen_string_literal: true

module Ci
  class StagePresenter < Gitlab::View::Presenter::Delegated
    presents :stage

    def latest_ordered_statuses
      preload_statuses(stage.statuses.latest_ordered)
    end

    def retried_ordered_statuses
      preload_statuses(stage.statuses.retried_ordered)
    end

    private

    def preload_statuses(statuses)
      common_relations = [:pipeline]

      preloaders = {
        ::Ci::Build => [:metadata, :tags, :job_artifacts_archive],
        ::Ci::Bridge => [:metadata, :downstream_pipeline],
        ::GenericCommitStatus => []
      }

      # rubocop: disable CodeReuse/ActiveRecord
      preloaders.each do |klass, relations|
        ActiveRecord::Associations::Preloader
          .new
          .preload(statuses.select { |job| job.is_a?(klass) }, relations + common_relations)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      statuses
    end
  end
end
