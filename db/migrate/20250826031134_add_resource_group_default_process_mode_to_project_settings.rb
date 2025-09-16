# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddResourceGroupDefaultProcessModeToProjectSettings < Gitlab::Database::Migration[2.3]
  # When using the methods "add_concurrent_index" or "remove_concurrent_index"
  # you must disable the use of transactions
  # as these methods can not run in an existing transaction.
  # When using "add_concurrent_index" or "remove_concurrent_index" methods make sure
  # that either of them is the _only_ method called in the migration,
  # any other changes should go in a separate migration.
  # This ensures that upon failure _only_ the index creation or removing fails
  # and can be retried or reverted easily.
  #
  # To disable transactions uncomment the following line and remove these
  # comments:
  # disable_ddl_transaction!
  #
  # Configure the `gitlab_schema` to perform data manipulation (DML).
  # Visit: https://docs.gitlab.com/ee/development/database/migrations_for_multiple_databases.html
  # restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  # Add dependent 'batched_background_migrations.queued_migration_version' values.
  # DEPENDENT_BATCHED_BACKGROUND_MIGRATIONS = []
  milestone '18.4'

  PROCESS_MODE_UNORDERED = 0

  def up
    add_column :project_ci_cd_settings, :resource_group_default_process_mode, :integer,
      default: PROCESS_MODE_UNORDERED, null: false, limit: 2
  end

  def down
    remove_column :project_ci_cd_settings, :resource_group_default_process_mode
  end
end
