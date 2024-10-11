# frozen_string_literal: true

class AddDefaultValuetoEditorColumn < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    change_column_default :workspaces, :editor, from: nil, to: 'webide'
  end
end
