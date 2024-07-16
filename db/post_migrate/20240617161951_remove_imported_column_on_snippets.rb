# frozen_string_literal: true

class RemoveImportedColumnOnSnippets < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def up
    remove_column :snippets, :imported
  end

  def down
    add_column :snippets, :imported, :integer, default: 0, null: false, limit: 2
  end
end
