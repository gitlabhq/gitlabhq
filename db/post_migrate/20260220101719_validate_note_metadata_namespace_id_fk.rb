# frozen_string_literal: true

class ValidateNoteMetadataNamespaceIdFk < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def up
    validate_foreign_key :note_metadata, :namespace_id, name: :fk_2a22435354
  end

  def down
    # no-op
  end
end
