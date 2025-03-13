# frozen_string_literal: true

class RetrySwitchRecordChangeTrackingToPCiRunnerMachinesTable < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  disable_ddl_transaction!

  milestone '17.10'

  PARTITIONED_TABLE = :ci_runner_machines
  TABLES = %i[
    instance_type_ci_runner_machines group_type_ci_runner_machines project_type_ci_runner_machines ci_runner_machines
  ].freeze

  def up
    # Remove current LFK trigger that is currently assigned to ci_runner_machines_archived, due to the call to
    # replace_with_partitioned_table:
    # CREATE TRIGGER ci_runner_machines_loose_fk_trigger AFTER DELETE ON ci_runner_machines_archived
    #   REFERENCING OLD TABLE AS old_table
    #   FOR EACH STATEMENT EXECUTE FUNCTION insert_into_loose_foreign_keys_deleted_records();
    with_lock_retries do
      # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- false positive
      drop_trigger(:ci_runner_machines_archived, :ci_runner_machines_loose_fk_trigger)
      # rubocop:enable Migration/WithLockRetriesDisallowedMethod
    end

    # Reattaching the new trigger function to the existing partitioned tables
    # but with an overridden table name
    TABLES.each do |table|
      with_lock_retries do
        untrack_record_deletions(table)

        track_record_deletions_override_table_name(table, PARTITIONED_TABLE)
      end
    end
  end

  def down
    TABLES.each do |table|
      with_lock_retries do
        untrack_record_deletions(table)
      end
    end

    # Mimic track_record_deletions but in a way to restore the previous state
    # (i.e. trigger on ci_runner_machines_archived but still named ci_runner_machines_loose_fk_trigger)
    with_lock_retries do
      execute(<<~SQL.squish)
        CREATE TRIGGER #{record_deletion_trigger_name(PARTITIONED_TABLE)}
        AFTER DELETE ON ci_runner_machines_archived REFERENCING OLD TABLE AS old_table
        FOR EACH STATEMENT
        EXECUTE FUNCTION #{INSERT_FUNCTION_NAME}();
      SQL
    end
  end
end
