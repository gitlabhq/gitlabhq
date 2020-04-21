# frozen_string_literal: true

class AddSuggestionCommitMessageToProjects < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  # rubocop:disable Migration/AddColumnsToWideTables
  # rubocop:disable Migration/PreventStrings
  def change
    add_column :projects, :suggestion_commit_message, :string, limit: 255
  end
  # rubocop:enable Migration/PreventStrings
  # rubocop:enable Migration/AddColumnsToWideTables
end
