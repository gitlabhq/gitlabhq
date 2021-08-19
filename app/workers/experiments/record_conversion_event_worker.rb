# frozen_string_literal: true

module Experiments
  class RecordConversionEventWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    feature_category :users
    tags :exclude_from_kubernetes
    urgency :low

    idempotent!

    def perform(experiment, user_id)
      return unless Gitlab::Experimentation.active?(experiment)

      ::Experiment.record_conversion_event(experiment, user_id)
    end
  end
end
