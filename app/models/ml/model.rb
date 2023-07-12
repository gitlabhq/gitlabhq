# frozen_string_literal: true

module Ml
  class Model < ApplicationRecord
    validates :project, :default_experiment, presence: true
    validates :name,
      format: Gitlab::Regex.ml_model_name_regex,
      uniqueness: { scope: :project },
      presence: true,
      length: { maximum: 255 }

    validate :valid_default_experiment?

    has_one :default_experiment, class_name: 'Ml::Experiment'
    belongs_to :project

    def valid_default_experiment?
      return unless default_experiment

      errors.add(:default_experiment) unless default_experiment.name == name
      errors.add(:default_experiment) unless default_experiment.project_id == project_id
    end
  end
end
