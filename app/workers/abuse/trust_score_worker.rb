# frozen_string_literal: true

module Abuse
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

      Abuse::TrustScore.create!(user: user, source: source, score: score.to_f, correlation_id_value: correlation_id)
    end
  end
end
