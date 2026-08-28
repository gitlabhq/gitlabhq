# frozen_string_literal: true

module MergeRequests
  class RiskAssessment < ApplicationRecord
    include ShaAttribute

    MIN_SCORE = 0
    MAX_SCORE = 100
    SCHEMA_SIZE_LIMIT = 64.kilobytes

    sha_attribute :diff_sha

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
      json_schema: {
        filename: 'merge_requests_risk_assessment_classification',
        size_limit: SCHEMA_SIZE_LIMIT
      }
    validates :signal_breakdown,
      json_schema: {
        filename: 'merge_requests_risk_assessment_signal_breakdown',
        size_limit: SCHEMA_SIZE_LIMIT
      }

    populate_sharding_key :project_id, source: :merge_request

    # Placeholder until https://gitlab.com/gitlab-org/gitlab/-/work_items/609301
    # adds the real scoring function and tier thresholds. Always nil for now,
    # consistent with score never being set either.
    def tier
      nil
    end

    state_machine :status, initial: :pending do
      state :pending, value: 0
      state :queued, value: 1
      state :complete, value: 2
      state :stale, value: 3

      event :refresh do
        transition %i[pending queued complete] => :queued,
          if: ->(assessment, *args) { assessment.refreshable_for?(args.first) }
      end

      # refresh(diff_sha, classification) - the event args aren't declared on
      # the event itself, so they're read back off the transition instead.
      after_transition on: :refresh do |assessment, transition|
        diff_sha, classification = transition.args
        assessment.enqueue_risk_score_calculation(diff_sha, classification)
      end
    end

    # Guards `refresh` so an out-of-order submission can't regress a newer result.
    # Callers holding a row lock get this checked against the locked row, which is
    # what makes concurrent submissions safe.
    def refreshable_for?(incoming_diff_sha)
      incoming_ordinal = revision_ordinal(incoming_diff_sha)
      # A revision that isn't in this merge request's history can't be placed
      # relative to the current one, so it's refused rather than guessed at.
      return false unless incoming_ordinal

      current_ordinal = revision_ordinal(diff_sha)
      # Nothing to be stale against: either a brand-new assessment, or the diff it
      # was built from has since been pruned. Fail open rather than wedge the row.
      return true unless current_ordinal

      incoming_ordinal >= current_ordinal
    end

    # Placeholder entrypoint for the scoring worker landing in
    # https://gitlab.com/gitlab-org/gitlab/-/work_items/609292. That worker owns
    # writing diff_sha and classification onto this record; replace this body
    # with its `.perform_async` call once it exists.
    def enqueue_risk_score_calculation(diff_sha, classification); end

    private

    # diff_sha values aren't ordered on their own (a rebase or amend produces a SHA
    # with no ancestry relation to the one it replaces), so ordering is delegated to
    # the merge request's own push history.
    def revision_ordinal(sha)
      merge_request.merge_request_diffs.ordinal_for(sha)
    end
  end
end
