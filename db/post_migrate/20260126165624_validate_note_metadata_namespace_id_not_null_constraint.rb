# frozen_string_literal: true

class ValidateNoteMetadataNamespaceIdNotNullConstraint < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  CONSTRAINT_NAME = 'check_67a890ebba'

  def up
    validate_not_null_constraint :note_metadata, :namespace_id, constraint_name: CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end
