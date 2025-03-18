# frozen_string_literal: true

class SwitchRecordChangeTrackingToPartitionedCiRunnersTable2 < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers
  include Gitlab::Database::SchemaHelpers

  disable_ddl_transaction!

  milestone '17.10'

  PARTITIONED_TABLE = :ci_runners
  TABLES = %i[instance_type_ci_runners group_type_ci_runners project_type_ci_runners ci_runners].freeze

  def up
    # Remove current LFK trigger that is currently assigned to ci_runners_archived, due to the call to
    # replace_with_partitioned_table:
    # CREATE TRIGGER ci_runners_loose_fk_trigger AFTER DELETE ON ci_runners_archived REFERENCING OLD TABLE AS old_table
    #   FOR EACH STATEMENT EXECUTE FUNCTION insert_into_loose_foreign_keys_deleted_records();
    drop_trigger(:ci_runners_archived, :ci_runners_loose_fk_trigger, if_exists: true)

    TABLES.each do |table|
      with_lock_retries do
        untrack_record_deletions(table)

        # Reattaching the new trigger function to the existing partitioned tables
        # but with an overridden table name
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
    # (i.e. trigger on ci_runners_archived but still named ci_runners_loose_fk_trigger)
    execute(<<~SQL.squish)
      CREATE TRIGGER #{record_deletion_trigger_name(:ci_runners)}
      AFTER DELETE ON ci_runners_archived REFERENCING OLD TABLE AS old_table
      FOR EACH STATEMENT
      EXECUTE FUNCTION #{INSERT_FUNCTION_NAME}();
    SQL
  end
end
