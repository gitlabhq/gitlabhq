# frozen_string_literal: true

class ValidateNoteDiffFilesNamespaceIdFk < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def up
    validate_foreign_key :note_diff_files, :namespace_id, name: :fk_a3c1c679d6
  end

  def down
    # no-op
  end
end
