# rubocop:disable Migration/Timestamps
class CreateSystemNoteMetadata < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :system_note_metadata do |t|
      t.references :note, null: false
      t.integer :commit_count
      t.string :action

      t.timestamps null: false
    end

    add_concurrent_foreign_key :system_note_metadata, :notes, column: :note_id
  end

  def down
    drop_table :system_note_metadata
  end
end
