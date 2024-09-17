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
      user = User.find_by_id(user_id)
      return unless user

      cache_key = "abuse:trust_score_cleanup_worker:#{user.id}:#{source}"
      return if Rails.cache.exist?(cache_key)

      AntiAbuse::UserTrustScore.new(user).remove_old_scores(source)
      Rails.cache.write(cache_key, true, expires_in: 5.minutes)
    end
  end
end
