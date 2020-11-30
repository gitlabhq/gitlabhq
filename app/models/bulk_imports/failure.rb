# frozen_string_literal: true

class BulkImports::Failure < ApplicationRecord
  self.table_name = 'bulk_import_failures'

  belongs_to :entity,
    class_name: 'BulkImports::Entity',
    foreign_key: :bulk_import_entity_id,
    inverse_of: :failures,
    optional: false

  validates :entity, presence: true
end
