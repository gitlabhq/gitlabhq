# frozen_string_literal: true

class AddProjectSettingsPreviousDefaultBranch < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20210707173645_add_project_settings_previous_default_branch_text_limit
  def up
    with_lock_retries do
      add_column :project_settings, :previous_default_branch, :text
    end
  end
  # rubocop:enable Migration/AddLimitToTextColumns

  def down
    with_lock_retries do
      remove_column :project_settings, :previous_default_branch
    end
  end
end
