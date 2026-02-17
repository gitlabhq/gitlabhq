# frozen_string_literal: true

class ValidateSystemNoteMetadataNamespaceIdFkAsync < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  def up
    prepare_async_foreign_key_validation :system_note_metadata, name: :fk_7836f9b848
  end

  def down
    unprepare_async_foreign_key_validation :system_note_metadata, name: :fk_7836f9b848
  end
end
