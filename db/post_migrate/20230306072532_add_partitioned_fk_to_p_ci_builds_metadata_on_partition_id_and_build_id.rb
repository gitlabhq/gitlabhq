# frozen_string_literal: true

class AddPartitionedFkToPCiBuildsMetadataOnPartitionIdAndBuildId < Gitlab::Database::Migration[2.1]
  SOURCE_TABLE_NAME = :p_ci_builds_metadata
  TARGET_TABLE_NAME = :ci_builds
  FK_NAME = :fk_e20479742e_p

  disable_ddl_transaction!

  def up
    return if foreign_key_exists?(SOURCE_TABLE_NAME, TARGET_TABLE_NAME, name: FK_NAME)

    with_lock_retries do
      execute("LOCK TABLE #{TARGET_TABLE_NAME}, #{SOURCE_TABLE_NAME} IN ACCESS EXCLUSIVE MODE")

      execute(<<~SQL.squish)
        ALTER TABLE #{SOURCE_TABLE_NAME}
        ADD CONSTRAINT #{FK_NAME}
        FOREIGN KEY (partition_id, build_id)
        REFERENCES #{TARGET_TABLE_NAME} (partition_id, id)
        ON UPDATE CASCADE ON DELETE CASCADE;
      SQL
    end
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(
        SOURCE_TABLE_NAME,
        TARGET_TABLE_NAME,
        name: FK_NAME,
        reverse_lock_order: true
      )
    end
  end
end
