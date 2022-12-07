# frozen_string_literal: true

class AddUniqueTokenEncryptedPartitionIdIndexToCiBuild < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_builds
  INDEX_NAME = :index_ci_builds_on_token_encrypted_partition_id_unique
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
