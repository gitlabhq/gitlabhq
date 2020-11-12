# frozen_string_literal: true

class CreateBulkImportTrackers < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      unless table_exists?(:bulk_import_trackers)
        create_table :bulk_import_trackers do |t|
          t.references :bulk_import_entity,
            null: false,
            index: false,
            foreign_key: { on_delete: :cascade }

          t.text :relation, null: false
          t.text :next_page
          t.boolean :has_next_page, default: false, null: false

          t.index %w(bulk_import_entity_id relation),
            unique: true,
            name: :bulk_import_trackers_uniq_relation_by_entity
        end
      end
    end

    add_check_constraint :bulk_import_trackers,
      '(has_next_page IS FALSE or next_page IS NOT NULL)',
      'check_next_page_requirement'
    add_text_limit :bulk_import_trackers, :relation, 255
    add_text_limit :bulk_import_trackers, :next_page, 255
  end

  def down
    with_lock_retries do
      drop_table :bulk_import_trackers
    end
  end
end
