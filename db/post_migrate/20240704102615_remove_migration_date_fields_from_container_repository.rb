# frozen_string_literal: true

class RemoveMigrationDateFieldsFromContainerRepository < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.2'

  def up
    with_lock_retries do
      remove_column :container_repositories, :migration_pre_import_started_at
      remove_column :container_repositories, :migration_pre_import_done_at
      remove_column :container_repositories, :migration_import_started_at
      remove_column :container_repositories, :migration_import_done_at
      remove_column :container_repositories, :migration_aborted_at
      remove_column :container_repositories, :migration_skipped_at
      remove_column :container_repositories, :migration_plan
    end
  end

  def down
    with_lock_retries do
      add_column :container_repositories, :migration_pre_import_started_at, :datetime_with_timezone, if_not_exists: true
      add_column :container_repositories, :migration_pre_import_done_at, :datetime_with_timezone, if_not_exists: true
      add_column :container_repositories, :migration_import_started_at, :datetime_with_timezone, if_not_exists: true
      add_column :container_repositories, :migration_import_done_at, :datetime_with_timezone, if_not_exists: true
      add_column :container_repositories, :migration_aborted_at, :datetime_with_timezone, if_not_exists: true
      add_column :container_repositories, :migration_skipped_at, :datetime_with_timezone, if_not_exists: true
      add_column :container_repositories, :migration_plan, :text, if_not_exists: true
    end

    add_text_limit :container_repositories, :migration_plan, 255
  end
end
