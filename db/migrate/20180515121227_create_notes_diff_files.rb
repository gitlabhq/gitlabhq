class CreateNotesDiffFiles < ActiveRecord::Migration
  DOWNTIME = false

  disable_ddl_transaction!

  def change
    create_table :note_diff_files do |t|
      t.references :diff_note, references: :notes, null: false, index: { unique: true }
      t.text :diff, null: false
      t.boolean :new_file, null: false
      t.boolean :renamed_file, null: false
      t.boolean :deleted_file, null: false
      t.string :a_mode, null: false
      t.string :b_mode, null: false
      t.text :new_path, null: false
      t.text :old_path, null: false
    end

    # rubocop:disable Migration/AddConcurrentForeignKey
    add_foreign_key :note_diff_files, :notes, column: :diff_note_id, on_delete: :cascade
  end
end
