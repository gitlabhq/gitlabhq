# frozen_string_literal: true

class AddTokenEncryptedPartitionIdIndexToCiBuild < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = :ci_builds
  INDEX_NAME = :unique_ci_builds_token_encrypted_and_partition_id
  COLUMNS = %i[token_encrypted partition_id].freeze

  def up
    prepare_async_index(
      TABLE_NAME,
      COLUMNS,
      where: 'token_encrypted IS NOT NULL',
      unique: true,
      name: INDEX_NAME
    )
  end

  def down
    unprepare_async_index(TABLE_NAME, COLUMNS, name: INDEX_NAME)
  end
end
