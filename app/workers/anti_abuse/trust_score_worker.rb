# frozen_string_literal: true

module AntiAbuse
  class TrustScoreWorker
    include ApplicationWorker

    data_consistency :delayed

    idempotent!
    feature_category :instance_resiliency
    urgency :low

    def perform(user_id, source, score, correlation_id = '')
      # nop
    end
  end
end
