# frozen_string_literal: true

class AddSuggestionCommitMessageToProjects < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :projects, :suggestion_commit_message, :string, limit: 255
  end
end
