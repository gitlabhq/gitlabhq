# frozen_string_literal: true

class ValidateDraftNotesProjectIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    validate_not_null_constraint :draft_notes, :project_id
  end

  def down
    # no-op
  end
end
