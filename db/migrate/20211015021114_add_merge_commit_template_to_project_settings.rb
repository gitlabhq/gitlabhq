# frozen_string_literal: true

class AddMergeCommitTemplateToProjectSettings < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    add_column :project_settings, :merge_commit_template, :text # rubocop:disable Migration/AddLimitToTextColumns
  end
end
