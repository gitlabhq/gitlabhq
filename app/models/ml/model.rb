# frozen_string_literal: true

module Ml
  class Model < ApplicationRecord
    include Presentable

    validates :project, :default_experiment, presence: true
    validates :name,
      format: Gitlab::Regex.ml_model_name_regex,
      uniqueness: { scope: :project },
      presence: true,
      length: { maximum: 255 }

    validate :valid_default_experiment?

    has_one :default_experiment, class_name: 'Ml::Experiment'
    belongs_to :project
    has_many :versions, class_name: 'Ml::ModelVersion'
    has_one :latest_version, -> { latest_by_model }, class_name: 'Ml::ModelVersion', inverse_of: :model

    scope :including_latest_version, -> { includes(:latest_version) }
    scope :by_project, ->(project) { where(project_id: project.id) }

    def valid_default_experiment?
      return unless default_experiment

      errors.add(:default_experiment) unless default_experiment.name == name
      errors.add(:default_experiment) unless default_experiment.project_id == project_id
    end

    def self.find_or_create(project, name, experiment)
      create_with(default_experiment: experiment)
        .find_or_create_by(project: project, name: name)
    end
  end
end
