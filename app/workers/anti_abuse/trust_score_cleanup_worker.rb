# frozen_string_literal: true

module AntiAbuse
  class TrustScoreCleanupWorker
    include ApplicationWorker

    idempotent!
    data_consistency :delayed
    deduplicate :until_executed
    feature_category :instance_resiliency
    urgency :low

    def perform(user_id, source)
      # nop
    end
  end
end
