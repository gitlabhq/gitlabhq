# frozen_string_literal: true

module Ml
  class CandidateMetric < ApplicationRecord
    validates :candidate, presence: true
    validates :name, length: { maximum: 250 }, presence: true

    belongs_to :candidate, class_name: 'Ml::Candidate'

    scope :latest, -> { select('DISTINCT ON (candidate_id, name) *').order('candidate_id, name, id DESC') }
    scope :for_history, ->(candidate_id, metric_name) {
      where(candidate_id: candidate_id, name: metric_name)
        .order(step: :asc, tracked_at: :asc)
    }
  end
end
