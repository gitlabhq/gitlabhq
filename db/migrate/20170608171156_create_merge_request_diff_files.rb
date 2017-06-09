class CreateMergeRequestDiffFiles < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :merge_request_diff_files, id: false do |t|
      t.integer :merge_request_diff_id, null: false
      t.integer :relative_order, null: false
      t.boolean :new_file, null: false
      t.boolean :renamed_file, null: false
      t.boolean :deleted_file, null: false
      t.boolean :too_large, null: false
      t.string :new_path, null: false
      t.string :old_path, null: false
      t.string :a_mode, null: false
      t.string :b_mode, null: false
      t.text :diff, null: false
    end

    add_index :merge_request_diff_files, [:merge_request_diff_id, :relative_order], name: 'index_merge_request_diff_files_on_mr_diff_id_and_order'

    add_concurrent_foreign_key :merge_request_diff_files, :merge_request_diffs, column: :merge_request_diff_id, on_delete: :cascade
  end

  def down
    drop_table :merge_request_diff_files
  end
end
