# frozen_string_literal: true

module Ml
  class ModelVersionMetadata < ApplicationRecord
    validates :name,
      length: { maximum: 255 },
      presence: true,
      uniqueness: { scope: :model_version, message: ->(metadata, _) { "'#{metadata.name}' already taken" } }
    validates :value, length: { maximum: 5000 }, presence: true

    belongs_to :project, optional: false
    belongs_to :model_version, class_name: 'Ml::ModelVersion', optional: false
  end
end
