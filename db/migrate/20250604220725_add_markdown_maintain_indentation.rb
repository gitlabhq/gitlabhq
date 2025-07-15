# frozen_string_literal: true

class AddMarkdownMaintainIndentation < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def up
    add_column :user_preferences, :markdown_maintain_indentation, :boolean, default: false, null: false
  end

  def down
    remove_column :user_preferences, :markdown_maintain_indentation, :boolean
  end
end
