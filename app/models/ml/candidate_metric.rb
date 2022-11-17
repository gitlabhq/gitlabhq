# frozen_string_literal: true

module Ml
  class CandidateMetric < ApplicationRecord
    validates :candidate, presence: true
    validates :name, length: { maximum: 250 }, presence: true

    belongs_to :candidate, class_name: 'Ml::Candidate'

    scope :latest, -> { select('DISTINCT ON (candidate_id, name) *').order('candidate_id, name, id DESC') }
  end
end
