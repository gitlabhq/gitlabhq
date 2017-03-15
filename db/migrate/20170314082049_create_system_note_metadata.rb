class CreateSystemNoteMetadata < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    create_table :system_note_metadata do |t|
      t.references :note, null: false
      t.integer :commit_count
      t.string :icon

      t.timestamps null: false
    end

    add_concurrent_foreign_key :system_note_metadata, :notes, column: :note_id, on_delete: :cascade
  end
end
