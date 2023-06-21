# frozen_string_literal: true

module Abuse
  class TrustScore < ApplicationRecord
    MAX_EVENTS = 100
    SPAMCHECK_HAM_THRESHOLD = 0.5

    self.table_name = 'abuse_trust_scores'

    enum source: Enums::Abuse::Source.sources

    belongs_to :user

    validates :user, presence: true
    validates :score, presence: true
    validates :source, presence: true

    scope :order_created_at_asc, -> { order(created_at: :asc) }
    scope :order_created_at_desc, -> { order(created_at: :desc) }

    before_create :assign_correlation_id
    after_commit :remove_old_scores

    private

    def assign_correlation_id
      self.correlation_id_value ||= (Labkit::Correlation::CorrelationId.current_id || '')
    end

    def remove_old_scores
      user_scores = Abuse::UserTrustScore.new(user)
      count = user_scores.trust_scores_for_source(source).count
      return unless count > MAX_EVENTS

      TrustScore.delete(
        user_scores.trust_scores_for_source(source)
        .order_created_at_asc
        .limit(count - MAX_EVENTS)
      )
    end
  end
end
