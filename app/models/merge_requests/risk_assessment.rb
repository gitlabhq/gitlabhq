# frozen_string_literal: true

module MergeRequests
  class RiskAssessment < ApplicationRecord
    include ShaAttribute

    MIN_SCORE = 0
    MAX_SCORE = 100

    sha_attribute :diff_sha

    enum :status, { pending: 0, completed: 1, failed: 2 }

    belongs_to :merge_request, optional: false, inverse_of: :risk_assessment

    has_many :risk_outcomes, class_name: 'MergeRequests::RiskOutcome',
      inverse_of: :risk_assessment

    validates :merge_request_id, uniqueness: true
    validates :project_id, presence: true
    validates :status, presence: true
    validates :diff_sha, presence: true, length: { maximum: 64 }

    validates :score, :confidence,
      numericality: {
        only_integer: true,
        greater_than_or_equal_to: MIN_SCORE,
        less_than_or_equal_to: MAX_SCORE
      },
      allow_nil: true

    validates :scoring_function_version, length: { maximum: 20 }
    validates :rationale, length: { maximum: 2048 }

    validates :classification,
      json_schema: { filename: 'merge_requests_risk_assessment_classification', size_limit: 64.kilobytes }
    validates :signal_breakdown,
      json_schema: { filename: 'merge_requests_risk_assessment_signal_breakdown', size_limit: 64.kilobytes }

    populate_sharding_key :project_id, source: :merge_request

    # Placeholder until https://gitlab.com/gitlab-org/gitlab/-/work_items/609301
    # adds the real scoring function and tier thresholds. Always nil for now,
    # consistent with score never being set either.
    def tier
      nil
    end

    def stale?
      diff_sha != merge_request.diff_head_sha
    end
  end
end
