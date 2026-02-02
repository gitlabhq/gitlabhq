# frozen_string_literal: true

class ValidateDiffNotePositionsNamespaceIdNotNullConstraint < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  CONSTRAINT_NAME = 'check_4c86140f48'

  def up
    validate_not_null_constraint :diff_note_positions, :namespace_id, constraint_name: CONSTRAINT_NAME
  end

  def down
    # not-op
  end
end
