# frozen_string_literal: true

module Counters
  class CleanupRefreshWorker
    include ApplicationWorker

    data_consistency :always

    loggable_arguments 0, 2

    # The counter is owned by several teams depending on the attribute
    feature_category :not_owned # rubocop:disable Gitlab/AvoidFeatureCategoryNotOwned

    urgency :low
    deduplicate :until_executing, including_scheduled: true

    idempotent!

    def perform(model_name, model_id, attribute)
      Gitlab::ApplicationContext.push(feature_category: :job_artifacts) if attribute.to_s == 'build_artifacts_size'

      return unless self.class.const_defined?(model_name)

      model_class = model_name.constantize
      model = model_class.find_by_id(model_id)
      return unless model

      Gitlab::Counters::BufferedCounter.new(model, attribute).cleanup_refresh
    end
  end
end
