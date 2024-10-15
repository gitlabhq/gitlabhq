# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddGoalToDuoWorkflows < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  # rubocop:disable Migration/AddLimitToTextColumns -- limit is added in 20240918153150_add_text_limit_to_duo_workflows_goal
  def change
    add_column :duo_workflows_workflows, :goal, :text, null: true
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
