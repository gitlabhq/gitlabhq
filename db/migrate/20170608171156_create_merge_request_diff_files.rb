class CreateMergeRequestDiffFiles < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  disable_ddl_transaction!

  def change
    create_table :merge_request_diff_files, id: false do |t|
      t.belongs_to :merge_request_diff, null: false, foreign_key: { on_delete: :cascade }
      t.integer :relative_order, null: false
      t.boolean :new_file, null: false
      t.boolean :renamed_file, null: false
      t.boolean :deleted_file, null: false
      t.boolean :too_large, null: false
      t.string :a_mode, null: false
      t.string :b_mode, null: false
      t.text :new_path, null: false
      t.text :old_path, null: false
      t.text :diff, null: false
      t.index [:merge_request_diff_id, :relative_order], name: 'index_merge_request_diff_files_on_mr_diff_id_and_order', unique: true
    end
  end
end
