# frozen_string_literal: true

class AddGitlabSchemaToBatchedBackgroundMigrations < Gitlab::Database::Migration[2.0]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20220503035437_add_text_limit_to_batched_background_migrations_gitlab_schema
  def change
    add_column :batched_background_migrations, :gitlab_schema, :text, null: false, default: :gitlab_main
    change_column_default(:batched_background_migrations, :gitlab_schema, from: :gitlab_main, to: nil)
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
