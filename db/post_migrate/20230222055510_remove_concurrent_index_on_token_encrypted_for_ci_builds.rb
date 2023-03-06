# frozen_string_literal: true

class RemoveConcurrentIndexOnTokenEncryptedForCiBuilds < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = :ci_builds
  COLUMN_NAME = :token_encrypted
  INDEX_NAME = :index_ci_builds_on_token_encrypted
  WHERE_STATEMENT = 'token_encrypted IS NOT NULL'

  def up
    remove_concurrent_index_by_name TABLE_NAME, name: INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, COLUMN_NAME, name: INDEX_NAME, where: WHERE_STATEMENT, unique: true
  end
end
