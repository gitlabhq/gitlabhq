class AddIndexToSystemNoteMetadata < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # MySQL automatically creates an index on a foreign-key constraint; PostgreSQL does not
    add_concurrent_index :system_note_metadata, :note_id, unique: true if Gitlab::Database.postgresql?
  end

  def down
    remove_concurrent_index :system_note_metadata, :note_id, unique: true if Gitlab::Database.postgresql?
  end
end
