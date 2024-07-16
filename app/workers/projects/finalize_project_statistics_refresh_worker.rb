# frozen_string_literal: true

module Projects
  class FinalizeProjectStatisticsRefreshWorker
    include ApplicationWorker

    data_consistency :always

    loggable_arguments 0, 1

    # The increments in `ProjectStatistics` are owned by several teams depending
    # on the counter
    feature_category :not_owned # rubocop:disable Gitlab/AvoidFeatureCategoryNotOwned

    urgency :low
    deduplicate :until_executing, including_scheduled: true

    idempotent!

    def perform(record_class, record_id)
      if record_class.demodulize == 'BuildArtifactsSizeRefresh'
        Gitlab::ApplicationContext.push(feature_category: :job_artifacts)
      end

      return unless self.class.const_defined?(record_class)

      record = record_class.constantize.find_by_id(record_id)
      return unless record

      record.finalize!
    end
  end
end
