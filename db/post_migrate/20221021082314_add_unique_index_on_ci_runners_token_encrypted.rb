# frozen_string_literal: true

class AddUniqueIndexOnCiRunnersTokenEncrypted < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_uniq_ci_runners_on_token_encrypted'

  def up
    add_concurrent_index :ci_runners,
      :token_encrypted,
      name: INDEX_NAME,
      unique: true
  end

  def down
    remove_concurrent_index_by_name :ci_runners, INDEX_NAME
  end
end
