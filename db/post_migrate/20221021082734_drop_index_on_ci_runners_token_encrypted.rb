# frozen_string_literal: true

class DropIndexOnCiRunnersTokenEncrypted < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_runners_on_token_encrypted'

  def up
    remove_concurrent_index_by_name :ci_runners, INDEX_NAME
  end

  def down
    add_concurrent_index :ci_runners,
                         :token_encrypted,
                         name: INDEX_NAME
  end
end
