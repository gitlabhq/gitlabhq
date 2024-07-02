# frozen_string_literal: true

module Import
  class SourceUserPlaceholderReference < ApplicationRecord
    self.table_name = 'import_source_user_placeholder_references'

    belongs_to :source_user, class_name: 'Import::SourceUser'
    belongs_to :namespace

    validates :model, :namespace_id, :source_user_id, :user_reference_column, presence: true
    validates :numeric_key, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
    validates :composite_key,
      json_schema: { filename: 'import_source_user_placeholder_reference_composite_key' },
      allow_nil: true
    validate :validate_numeric_or_composite_key_present

    attribute :composite_key, :ind_jsonb

    private

    def validate_numeric_or_composite_key_present
      return if numeric_key.present? ^ composite_key.present?

      errors.add(:base, :blank, message: 'numeric_key or composite_key must be present')
    end
  end
end
