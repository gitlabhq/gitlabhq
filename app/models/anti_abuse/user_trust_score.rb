# frozen_string_literal: true

module AntiAbuse
  class UserTrustScore
    MAX_EVENTS = 100
    SPAMCHECK_HAM_THRESHOLD = 0.5

    def initialize(user)
      @user = user
    end

    def spammer?
      spam_score > SPAMCHECK_HAM_THRESHOLD
    end

    def spam_score
      user_scores.spamcheck.average(:score) || 0.0
    end

    def telesign_score
      user_scores.telesign.order_created_at_desc.first&.score || 0.0
    end

    def arkose_global_score
      user_scores.arkose_global_score.order_created_at_desc.first&.score || 0.0
    end

    def arkose_custom_score
      user_scores.arkose_custom_score.order_created_at_desc.first&.score || 0.0
    end

    def trust_scores_for_source(source)
      user_scores.where(source: source)
    end

    def remove_old_scores(source)
      count = trust_scores_for_source(source).count
      return unless count > MAX_EVENTS

      AntiAbuse::TrustScore.delete(
        trust_scores_for_source(source)
        .order_created_at_asc
        .limit(count - MAX_EVENTS)
      )
    end

    private

    def user_scores
      AntiAbuse::TrustScore.where(user_id: @user.id)
    end
  end
end
