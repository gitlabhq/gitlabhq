# frozen_string_literal: true

class CreateGroupGroupLinks < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :group_group_links do |t|
      t.integer :shared_group_id
      t.integer :shared_with_group_id
      t.integer :group_access, default: 30, null: false
      t.date :expires_at
    end

    add_concurrent_foreign_key :group_group_links,
                               :namespaces,
                               column: :shared_group_id,
                               on_delete: :cascade
    add_concurrent_index :group_group_links, :shared_group_id
    change_column_null :group_group_links, :shared_group_id, false

    add_concurrent_foreign_key :group_group_links,
                               :namespaces,
                               column: :shared_with_group_id,
                               on_delete: :cascade
    add_concurrent_index :group_group_links, :shared_with_group_id
    change_column_null :group_group_links, :shared_with_group_id, false

    add_concurrent_index :group_group_links,
                         [:shared_group_id, :shared_with_group_id],
                         unique: true,
                         name: 'index_group_group_links_on_shared_group_and_shared_with_group'
  end

  def down
    drop_table :group_group_links
  end
end
