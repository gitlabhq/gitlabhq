# frozen_string_literal: true

class CreateDependencyListExportsTable < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    create_table :dependency_list_exports do |t|
      t.timestamps_with_timezone null: false
      t.bigint :project_id, null: false
      t.bigint :user_id
      t.integer :file_store
      t.integer :status, default: 0, null: false, limit: 2
      t.text :file, limit: 255

      t.index :user_id
      t.index :project_id
    end
  end

  def down
    drop_table :dependency_list_exports
  end
end
