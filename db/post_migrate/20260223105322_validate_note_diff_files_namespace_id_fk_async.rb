# frozen_string_literal: true

class ValidateNoteDiffFilesNamespaceIdFkAsync < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def up
    prepare_async_foreign_key_validation :note_diff_files, name: :fk_a3c1c679d6
  end

  def down
    unprepare_async_foreign_key_validation :note_diff_files, name: :fk_a3c1c679d6
  end
end
