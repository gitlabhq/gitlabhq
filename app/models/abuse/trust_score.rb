# frozen_string_literal: true

module Abuse
  class TrustScore < ApplicationRecord
    MAX_EVENTS = 100

    self.table_name = 'abuse_trust_scores'

    enum source: Enums::Abuse::Source.sources

    belongs_to :user

    validates :user, presence: true
    validates :score, presence: true
    validates :source, presence: true

    before_create :assign_correlation_id
    after_commit :remove_old_scores

    private

    def assign_correlation_id
      self.correlation_id_value ||= (Labkit::Correlation::CorrelationId.current_id || '')
    end

    def remove_old_scores
      count = user.trust_scores_for_source(source).count
      return unless count > MAX_EVENTS

      TrustScore.delete(
        user.trust_scores_for_source(source)
        .order(created_at: :asc)
        .limit(count - MAX_EVENTS)
      )
    end
  end
end
