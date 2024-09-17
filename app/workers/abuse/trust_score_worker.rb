# frozen_string_literal: true

module Abuse
  class TrustScoreWorker
    include ApplicationWorker

    data_consistency :delayed

    idempotent!
    feature_category :instance_resiliency
    urgency :low

    def perform(user_id, source, score, correlation_id = '')
      AntiAbuse::TrustScoreWorker.new.perform(user_id, source, score, correlation_id)
    end
  end
end
