# frozen_string_literal: true

class ValidateSystemNoteMetadataNamespaceIdFk < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  def up
    validate_foreign_key :system_note_metadata, :namespace_id, name: :fk_7836f9b848
  end

  def down
    # no-op
  end
end
