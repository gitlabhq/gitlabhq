# frozen_string_literal: true

module Ml
  class ModelMetadata < ApplicationRecord
    validates :name,
      length: { maximum: 255 },
      presence: true,
      uniqueness: { scope: :model, message: ->(metadata, _) { "'#{metadata.name}' already taken" } }
    validates :value, length: { maximum: 5000 }, presence: true

    belongs_to :model, class_name: 'Ml::Model', optional: false
  end
end
