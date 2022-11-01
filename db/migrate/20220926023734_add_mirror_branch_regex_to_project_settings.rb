# frozen_string_literal: true

class AddMirrorBranchRegexToProjectSettings < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20221027124848_add_text_limit_to_project_settings_mirror_branch_regex.rb
  def change
    add_column :project_settings, :mirror_branch_regex, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
