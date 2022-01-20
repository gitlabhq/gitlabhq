# frozen_string_literal: true

class AddMigrationColumnsToContainerRepositories < Gitlab::Database::Migration[1.0]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20220117225936_add_text_limits_to_container_repositories_migration_columns.rb
  def change
    add_column :container_repositories, :migration_pre_import_started_at, :datetime_with_timezone
    add_column :container_repositories, :migration_pre_import_done_at, :datetime_with_timezone
    add_column :container_repositories, :migration_import_started_at, :datetime_with_timezone
    add_column :container_repositories, :migration_import_done_at, :datetime_with_timezone
    add_column :container_repositories, :migration_aborted_at, :datetime_with_timezone
    add_column :container_repositories, :migration_skipped_at, :datetime_with_timezone
    add_column :container_repositories, :migration_retries_count, :integer, default: 0, null: false
    add_column :container_repositories, :migration_skipped_reason, :smallint
    add_column :container_repositories, :migration_state, :text, default: 'default', null: false
    add_column :container_repositories, :migration_aborted_in_state, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
