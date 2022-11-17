# frozen_string_literal: true

class DisableFastupdateOnIssuesTitleGinIndex < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_issues_on_title_trigram'

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
