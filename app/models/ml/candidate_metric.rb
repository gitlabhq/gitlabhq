# frozen_string_literal: true

module Ml
  class CandidateMetric < ApplicationRecord
    validates :candidate, presence: true
    validates :name, length: { maximum: 250 }, presence: true

    belongs_to :candidate, class_name: 'Ml::Candidate'
  end
end
