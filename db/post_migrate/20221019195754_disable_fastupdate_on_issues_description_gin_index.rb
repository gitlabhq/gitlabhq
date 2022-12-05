# frozen_string_literal: true

class DisableFastupdateOnIssuesDescriptionGinIndex < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_issues_on_description_trigram'

  def up
    return unless index_exists_by_name?(:issues, INDEX_NAME)

    with_lock_retries do
      execute <<~SQL
        ALTER INDEX #{INDEX_NAME} SET ( fastupdate = false ) ;
      SQL
    end
  end

  def down
    return unless index_exists_by_name?(:issues, INDEX_NAME)

    with_lock_retries do
      execute <<~SQL
        ALTER INDEX #{INDEX_NAME} RESET ( fastupdate ) ;
      SQL
    end
  end
end
