# frozen_string_literal: true

class DropTempNotesBackupTable < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  TABLE_NAME = :temp_notes_backup

  def up
    drop_table TABLE_NAME
  end

  def down
    execute "CREATE TABLE IF NOT EXISTS #{TABLE_NAME} (LIKE notes);"
    execute "ALTER TABLE #{TABLE_NAME} ADD PRIMARY KEY (id);"
  end
end
