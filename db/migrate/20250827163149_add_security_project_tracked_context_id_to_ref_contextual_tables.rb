# frozen_string_literal: true

class AddSecurityProjectTrackedContextIdToRefContextualTables < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  disable_ddl_transaction!

  def up
    # rubocop:disable Migration/PreventAddingColumns -- The oversized nature of these tables will be addressed through planned partitioning
    with_lock_retries do
      add_column :vulnerability_occurrences, :security_project_tracked_context_id, :bigint, if_not_exists: true
    end
    with_lock_retries do
      add_column :vulnerability_reads, :security_project_tracked_context_id, :bigint, if_not_exists: true
    end
    # rubocop:enable Migration/PreventAddingColumns

    with_lock_retries do
      add_column :vulnerability_statistics, :security_project_tracked_context_id, :bigint, if_not_exists: true
    end
    with_lock_retries do
      add_column :vulnerability_historical_statistics, :security_project_tracked_context_id, :bigint,
        if_not_exists: true
    end
  end

  def down
    with_lock_retries do
      remove_column :vulnerability_occurrences, :security_project_tracked_context_id, :bigint, if_exists: true
    end
    with_lock_retries do
      remove_column :vulnerability_reads, :security_project_tracked_context_id, :bigint, if_exists: true
    end
    with_lock_retries do
      remove_column :vulnerability_statistics, :security_project_tracked_context_id, :bigint, if_exists: true
    end
    with_lock_retries do
      remove_column :vulnerability_historical_statistics, :security_project_tracked_context_id, :bigint, if_exists: true
    end
  end
end
