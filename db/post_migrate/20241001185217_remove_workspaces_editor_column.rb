# frozen_string_literal: true

class RemoveWorkspacesEditorColumn < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def up
    remove_column :workspaces, :editor
  end

  def down
    add_column :workspaces, :editor, :text, limit: 256, default: 'webide', null: false
  end
end
