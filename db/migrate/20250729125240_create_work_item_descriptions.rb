# frozen_string_literal: true

class CreateWorkItemDescriptions < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  skip_require_disable_ddl_transactions!
  milestone '18.4'

  TABLE_NAME = :work_item_descriptions

  def up
    create_table TABLE_NAME, if_not_exists: true, options: 'PARTITION BY HASH (root_namespace_id)',
      primary_key: [:work_item_id, :root_namespace_id] do |t|
      t.bigint :work_item_id, null: false
      t.bigint :namespace_id, null: false
      t.bigint :root_namespace_id, null: false
      t.bigint :last_edited_by_id
      t.integer :lock_version, default: 0
      t.integer :cached_markdown_version
      t.datetime :last_edited_at # rubocop:disable Migration/Datetime -- We are keeping it the same with issues table
      t.tsvector :search_vector
      t.text :description # rubocop:disable Migration/AddLimitToTextColumns -- keeps compatibility with existing table
      t.text :description_html # rubocop:disable Migration/AddLimitToTextColumns -- keeps compatibility with existing table

      t.index [:work_item_id, :root_namespace_id], unique: true,
        name: 'index_wi_descriptions_unique_work_item_id_root_namespace_id'
      t.index :namespace_id, name: 'index_work_item_descriptions_on_namespace_id'
      t.index :root_namespace_id, name: 'index_work_item_descriptions_on_root_namespace_id'
      t.index :last_edited_by_id, where: 'last_edited_by_id IS NOT NULL',
        name: 'index_work_item_descriptions_on_last_edited_by_id'
    end

    create_hash_partitions(TABLE_NAME, 64)
  end

  def down
    drop_table TABLE_NAME
  end
end
