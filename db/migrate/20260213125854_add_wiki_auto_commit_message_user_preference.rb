# frozen_string_literal: true

class AddWikiAutoCommitMessageUserPreference < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def change
    add_column :user_preferences, :wiki_use_auto_commit_message, :boolean, default: false, null: false
  end
end
