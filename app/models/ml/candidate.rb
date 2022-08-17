# frozen_string_literal: true

module Ml
  class Candidate < ApplicationRecord
    validates :iid, :experiment, presence: true

    belongs_to :experiment, class_name: 'Ml::Experiment'
    belongs_to :user
    has_many :metrics, class_name: 'Ml::CandidateMetric'
    has_many :params, class_name: 'Ml::CandidateParam'
  end
end
