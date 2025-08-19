# frozen_string_literal: true

class DropWorkItemRelatedLinkRestrictionTable < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def up
    drop_table :work_item_related_link_restrictions, if_exists: true
  end

  def down
    create_table :work_item_related_link_restrictions do |t|
      t.bigint :source_type_id, null: false
      t.bigint :target_type_id, null: false
      t.integer :link_type, limit: 2, null: false, default: 0
    end

    add_index :work_item_related_link_restrictions,
      [:source_type_id, :link_type, :target_type_id],
      unique: true,
      name: 'index_work_item_link_restrictions_on_source_link_type_target'

    add_index :work_item_related_link_restrictions, :target_type_id,
      name: 'index_work_item_related_link_restrictions_on_target_type_id'
  end
end
