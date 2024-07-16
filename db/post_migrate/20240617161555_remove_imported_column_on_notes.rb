# frozen_string_literal: true

class RemoveImportedColumnOnNotes < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def up
    remove_column :notes, :imported
  end

  def down
    add_column :notes, :imported, :integer, default: 0, null: false, limit: 2
  end
end
