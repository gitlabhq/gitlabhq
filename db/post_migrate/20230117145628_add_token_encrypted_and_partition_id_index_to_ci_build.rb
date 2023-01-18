# frozen_string_literal: true

class AddTokenEncryptedAndPartitionIdIndexToCiBuild < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = :ci_builds
  INDEX_NAME = :unique_ci_builds_token_encrypted_and_partition_id
  COLUMNS = %i[token_encrypted partition_id].freeze

  def up
    add_concurrent_index(TABLE_NAME, COLUMNS, unique: true, where: 'token_encrypted IS NOT NULL', name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
