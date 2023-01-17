# frozen_string_literal: true

class DropIndexOnCiBuildTokenEncrypted < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = :ci_builds
  INDEX_NAME = :index_ci_builds_on_token_encrypted_partition_id_unique
  COLUMNS = %i[token_encrypted partition_id].freeze

  def up
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, COLUMNS, unique: true, where: 'token_encrypted IS NOT NULL', name: INDEX_NAME)
  end
end
