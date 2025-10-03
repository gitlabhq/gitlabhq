# frozen_string_literal: true

class DropNoteUploads < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def up
    drop_table :note_uploads
  end

  def down
    execute <<~SQL
      CREATE TABLE note_uploads PARTITION OF uploads_9ba88c4165 FOR VALUES IN ('Note');
    SQL
  end
end
