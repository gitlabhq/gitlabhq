# frozen_string_literal: true

class AddSquashCommitTemplateToProjectSettings < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    add_column :project_settings, :squash_commit_template, :text # rubocop:disable Migration/AddLimitToTextColumns
  end
end
