# frozen_string_literal: true

module Experiments
  class RecordConversionEventWorker
    include ApplicationWorker

    feature_category :users
    urgency :low

    idempotent!

    def perform(experiment, user_id)
      return unless Gitlab::Experimentation.active?(experiment)

      ::Experiment.record_conversion_event(experiment, user_id)
    end
  end
end
