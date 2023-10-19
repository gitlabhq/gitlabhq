# frozen_string_literal: true

class AddRelatedLinkRestrictions < Gitlab::Database::Migration[2.1]
  UNIQUE_INDEX_NAME = 'index_work_item_link_restrictions_on_source_link_type_target'

  def up
    create_table :work_item_related_link_restrictions do |t|
      t.references :source_type, index: false, null: false,
        foreign_key: { on_delete: :cascade, to_table: :work_item_types }
      t.references :target_type, index: true, null: false,
        foreign_key: { on_delete: :cascade, to_table: :work_item_types }
      t.integer :link_type, null: false, limit: 2, default: 0

      t.index [:source_type_id, :link_type, :target_type_id], unique: true, name: UNIQUE_INDEX_NAME
    end
  end

  def down
    drop_table :work_item_related_link_restrictions
  end
end
