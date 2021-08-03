# frozen_string_literal: true

class CreateWorkItemTypes < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    create_table_with_constraints :work_item_types do |t|
      t.integer :base_type, limit: 2, default: 0, null: false
      t.integer :cached_markdown_version
      t.text :name, null: false
      t.text :description # rubocop:disable Migration/AddLimitToTextColumns
      t.text :description_html # rubocop:disable Migration/AddLimitToTextColumns
      t.text :icon_name, null: true
      t.references :namespace, foreign_key: { on_delete: :cascade }, index: false, null: true
      t.timestamps_with_timezone null: false

      t.text_limit :name, 255
      t.text_limit :icon_name, 255
    end

    add_concurrent_index :work_item_types,
                         'namespace_id, TRIM(BOTH FROM LOWER(name))',
                         unique: true,
                         name: :work_item_types_namespace_id_and_name_unique
  end

  def down
    with_lock_retries do
      drop_table :work_item_types
    end
  end
end
