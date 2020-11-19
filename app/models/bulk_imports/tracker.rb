# frozen_string_literal: true

# This model is responsible for keeping track of the requests/pagination
# happening during a Group Migration (BulkImport).
class BulkImports::Tracker < ApplicationRecord
  self.table_name = 'bulk_import_trackers'

  belongs_to :entity,
    class_name: 'BulkImports::Entity',
    foreign_key: :bulk_import_entity_id,
    optional: false

  validates :relation,
    presence: true,
    uniqueness: { scope: :bulk_import_entity_id }

  validates :next_page, presence: { if: :has_next_page? }
end
