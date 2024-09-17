# frozen_string_literal: true

module AntiAbuse
  class TrustScoreWorker
    include ApplicationWorker

    data_consistency :delayed

    idempotent!
    feature_category :instance_resiliency
    urgency :low

    def perform(user_id, source, score, correlation_id = '')
      user = User.find_by_id(user_id)
      unless user
        logger.info(structured_payload(message: "User not found.", user_id: user_id))
        return
      end

      AntiAbuse::TrustScore.create!(user: user, source: source, score: score.to_f, correlation_id_value: correlation_id)
      AntiAbuse::TrustScoreCleanupWorker.perform_async(user.id, source)
    end
  end
end
