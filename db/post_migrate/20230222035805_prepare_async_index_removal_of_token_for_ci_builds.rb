# frozen_string_literal: true

class PrepareAsyncIndexRemovalOfTokenForCiBuilds < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = :ci_builds
  COLUMN_NAME = :token_encrypted
  INDEX_NAME = :index_ci_builds_on_token_encrypted

  def up
    prepare_async_index_removal(TABLE_NAME, COLUMN_NAME, name: INDEX_NAME)
  end

  def down
    unprepare_async_index(TABLE_NAME, COLUMN_NAME, name: INDEX_NAME)
  end
end
