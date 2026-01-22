# frozen_string_literal: true

class ValidateSystemNoteMetadataNamespaceIdNotNullConstraint < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  def up
    validate_check_constraint :system_note_metadata, :check_9135b6f0b6
  end

  def down
    # no-op
  end
end
