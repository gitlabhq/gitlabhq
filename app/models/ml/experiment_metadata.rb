# frozen_string_literal: true

module Ml
  class ExperimentMetadata < ApplicationRecord
    validates :experiment, presence: true
    validates :name,
      length: { maximum: 250 },
      presence: true,
      uniqueness: { scope: :experiment, message: ->(exp, _) { "'#{exp.name}' already taken" } }
    validates :value, length: { maximum: 5000 }, presence: true

    belongs_to :experiment, class_name: 'Ml::Experiment'
  end
end
