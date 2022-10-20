# frozen_string_literal: true

class PrepareCiBuildsMetadataForPartitioningPrimaryKey < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  TABLE_NAME = 'ci_builds_metadata'
  PRIMARY_KEY = 'ci_builds_metadata_pkey'
  NEW_INDEX_NAME = 'index_ci_builds_metadata_on_id_partition_id_unique'
  OLD_INDEX_NAME = 'index_ci_builds_metadata_on_id_unique'

  def up
    with_lock_retries(raise_on_exhaustion: true) do
      execute("ALTER TABLE #{TABLE_NAME} DROP CONSTRAINT #{PRIMARY_KEY} CASCADE")

      rename_index(TABLE_NAME, NEW_INDEX_NAME, PRIMARY_KEY)

      execute("ALTER TABLE #{TABLE_NAME} ADD CONSTRAINT #{PRIMARY_KEY} " \
        "PRIMARY KEY USING INDEX #{PRIMARY_KEY}")
    end
  end

  # rolling back this migration is time consuming with the creation of these two indexes
  def down
    add_concurrent_index(TABLE_NAME, :id, unique: true, name: OLD_INDEX_NAME)
    add_concurrent_index(TABLE_NAME, [:id, :partition_id], unique: true, name: NEW_INDEX_NAME)

    with_lock_retries(raise_on_exhaustion: true) do
      execute("ALTER TABLE #{TABLE_NAME} DROP CONSTRAINT #{PRIMARY_KEY} CASCADE")

      rename_index(TABLE_NAME, OLD_INDEX_NAME, PRIMARY_KEY)

      execute("ALTER TABLE #{TABLE_NAME} ADD CONSTRAINT #{PRIMARY_KEY} " \
        "PRIMARY KEY USING INDEX #{PRIMARY_KEY}")
    end
  end
end
