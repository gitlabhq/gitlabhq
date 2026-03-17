# frozen_string_literal: true

class ValidateNoteDiffFilesNamespaceIdNotNullConstraint < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def up
    validate_check_constraint :note_diff_files, :check_ebb23d73d7
  end

  def down
    # no-op
  end
end
