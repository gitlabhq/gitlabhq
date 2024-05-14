# frozen_string_literal: true

class AddTempNotesBackupTable < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  TABLE_NAME = 'temp_notes_backup'

  def up
    execute "CREATE TABLE IF NOT EXISTS #{TABLE_NAME} (LIKE notes);"
    execute "ALTER TABLE #{TABLE_NAME} ADD PRIMARY KEY (id);"
  end

  def down
    execute "DROP TABLE IF EXISTS #{TABLE_NAME}"
  end
end
