# frozen_string_literal: true

module AntiAbuse
  class TrustScore < ApplicationRecord
    self.table_name = 'abuse_trust_scores'

    enum source: Enums::Abuse::Source.sources

    belongs_to :user

    validates :user, presence: true
    validates :score, presence: true
    validates :source, presence: true

    scope :order_created_at_asc, -> { order(created_at: :asc) }
    scope :order_created_at_desc, -> { order(created_at: :desc) }

    before_create :assign_correlation_id

    private

    def assign_correlation_id
      self.correlation_id_value ||= Labkit::Correlation::CorrelationId.current_id || ''
    end
  end
end
