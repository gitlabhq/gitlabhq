# frozen_string_literal: true

module MergeRequests
  class RiskOutcome < ApplicationRecord
    belongs_to :risk_assessment, class_name: 'MergeRequests::RiskAssessment', optional: false,
      inverse_of: :risk_outcomes

    validates :project_id, presence: true
    validates :observed_at, presence: true

    # Matches the unique index: one outcome per signal type per assessment.
    validates :signal_type, uniqueness: { scope: :risk_assessment_id }

    validates :signal_type, :confidence,
      presence: true,
      numericality: {
        only_integer: true,
        greater_than_or_equal_to: 0,
        less_than_or_equal_to: Gitlab::Database::MAX_SMALLINT_VALUE
      }

    validates :evidence, json_schema: { filename: 'merge_requests_risk_outcome_evidence', size_limit: 64.kilobytes }

    populate_sharding_key :project_id, source: :risk_assessment
  end
end
