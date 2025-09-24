# frozen_string_literal: true

# This migration changes the default text editor settings to use the rich text editor by default.
# This is part of the effort to make the rich text editor the default experience for all users.
# The change:
# text_editor_type: from 0 (not_set) to 2 (rich_text_editor)
class ChangeTextEditorTypeDefault < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  disable_ddl_transaction!

  def up
    change_column_default :user_preferences, :text_editor_type, from: 0, to: 2
  end

  def down
    change_column_default :user_preferences, :text_editor_type, from: 2, to: 0
  end
end
