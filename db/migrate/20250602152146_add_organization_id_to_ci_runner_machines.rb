# frozen_string_literal: true

class AddOrganizationIdToCiRunnerMachines < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  milestone "18.1"

  disable_ddl_transaction!

  TABLE_NAME = "ci_runner_machines"
  ARCHIVED_TABLE_NAME = "ci_runner_machines_archived"

  def up
    with_lock_retries do
      add_column(TABLE_NAME, :organization_id, :bigint, if_not_exists: true)
    end

    return unless archived_table_present?

    with_lock_retries do
      add_column(ARCHIVED_TABLE_NAME, :organization_id, :bigint, if_not_exists: true)
      recreate_sync_trigger # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- false positive
    end
  end

  def down
    with_lock_retries do
      remove_column(TABLE_NAME, :organization_id, if_exists: true)
    end

    return unless archived_table_present?

    with_lock_retries do
      remove_column(ARCHIVED_TABLE_NAME, :organization_id, if_exists: true)
      recreate_sync_trigger # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- false positive
    end
  end

  private

  # ci_runner_machines_archived was dropped in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189308
  # (18.0) as a post-deployment migration. This migration might end up being executed earlier than that migration in
  # self-managed environments.
  # Instead of waiting for a required stop in 18.2, we'll look at whether the archive table is still there.
  # If it is, we'll add the column there as well, and the table will end up being dropped later.
  def archived_table_present?
    table_exists?(ARCHIVED_TABLE_NAME)
  end

  def recreate_sync_trigger
    # Ensure organization_id state is reflected in the sync trigger
    drop_sync_trigger(TABLE_NAME)

    create_trigger_to_sync_tables(TABLE_NAME, ARCHIVED_TABLE_NAME, %w[id])
  end
end
