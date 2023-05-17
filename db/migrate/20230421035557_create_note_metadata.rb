# frozen_string_literal: true

class CreateNoteMetadata < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    create_table :note_metadata, id: false do |t|
      t.references :note,
        primary_key: true,
        null: false,
        type: :bigint,
        index: true,
        foreign_key: { on_delete: :cascade }
      t.text :email_participant, null: true, limit: 255
      t.timestamps_with_timezone null: true
    end
  end
end
