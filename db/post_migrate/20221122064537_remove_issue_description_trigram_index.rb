# frozen_string_literal: true

class RemoveIssueDescriptionTrigramIndex < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_issues_on_description_trigram'

  def up
    remove_concurrent_index_by_name :issues, name: INDEX_NAME
  end

  def down
    disable_statement_timeout do
      execute <<-SQL
        CREATE INDEX CONCURRENTLY IF NOT EXISTS #{INDEX_NAME} ON issues
          USING gin (description gin_trgm_ops) WITH (fastupdate='false')
      SQL
    end
  end
end
