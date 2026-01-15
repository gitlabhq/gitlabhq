# frozen_string_literal: true

class ValidateSystemNoteMetadataNamespaceIdNotNullConstraintAsync < Gitlab::Database::Migration[2.3]
  CONSTRAINT_NAME = 'check_9135b6f0b6'

  milestone '18.9'

  def up
    prepare_async_check_constraint_validation :system_note_metadata, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :system_note_metadata, name: CONSTRAINT_NAME
  end
end
