# frozen_string_literal: true

class DisableFastupdateOnMergeRequestsDescriptionGinIndex < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_merge_requests_on_description_trigram'

  def up
    with_lock_retries do
      execute <<~SQL
        ALTER INDEX #{INDEX_NAME} SET ( fastupdate = false ) ;
      SQL
    end
  end

  def down
    with_lock_retries do
      execute <<~SQL
        ALTER INDEX #{INDEX_NAME} RESET ( fastupdate ) ;
      SQL
    end
  end
end
