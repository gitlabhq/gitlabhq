# frozen_string_literal: true

class DropForeignKeyFromArchivedRecordsToArchives < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  FROM_TABLE = :vulnerability_archived_records
  TO_TABLE = :vulnerability_archives
  FK_NAME = :fk_rails_601e008d4b

  disable_ddl_transaction!
  milestone '18.1'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(FROM_TABLE, TO_TABLE, name: FK_NAME)
    end
  end

  def down
    add_concurrent_partitioned_foreign_key(
      FROM_TABLE,
      TO_TABLE,
      column: %i[archive_id date],
      target_column: %i[id date],
      name: FK_NAME,
      on_delete: :cascade
    )
  end
end
