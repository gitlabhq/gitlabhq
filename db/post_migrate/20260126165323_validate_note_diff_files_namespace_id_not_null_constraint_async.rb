# frozen_string_literal: true

class ValidateNoteDiffFilesNamespaceIdNotNullConstraintAsync < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  CONSTRAINT_NAME = 'check_ebb23d73d7'

  def up
    prepare_async_check_constraint_validation :note_diff_files, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :note_diff_files, name: CONSTRAINT_NAME
  end
end
