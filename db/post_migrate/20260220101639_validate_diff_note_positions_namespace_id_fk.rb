# frozen_string_literal: true

class ValidateDiffNotePositionsNamespaceIdFk < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def up
    validate_foreign_key :diff_note_positions, :namespace_id, name: :fk_9ccec9c22a
  end

  def down
    # no-op
  end
end
