# frozen_string_literal: true

class RemoveMigrationStateAndRetriesRelatedFieldsOnContainerRepositories < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.1'

  def up
    with_lock_retries do
      remove_column :container_repositories, :migration_aborted_in_state
      remove_column :container_repositories, :migration_retries_count
      remove_column :container_repositories, :migration_skipped_reason
      remove_column :container_repositories, :migration_state
    end
  end

  def down
    with_lock_retries do
      add_column :container_repositories, :migration_aborted_in_state, :text, if_not_exists: true
      add_column :container_repositories, :migration_retries_count,
        :integer, default: 0, null: false, if_not_exists: true
      add_column :container_repositories, :migration_skipped_reason, :smallint, if_not_exists: true
      add_column :container_repositories, :migration_state, :text, default: 'default', null: false, if_not_exists: true
    end

    add_text_limit :container_repositories, :migration_state, 255
    add_text_limit :container_repositories, :migration_aborted_in_state, 255
  end
end
