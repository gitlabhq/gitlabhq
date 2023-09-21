# frozen_string_literal: true

class SynchronouslyCreateIndexForUuidTypeCasting < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = :vulnerability_occurrences
  INDEX_NAME = "tmp_index_vulnerability_occurrences_uuid_cast"

  def up
    disable_statement_timeout do
      execute <<~SQL
        CREATE INDEX CONCURRENTLY IF NOT EXISTS #{INDEX_NAME}
        ON #{TABLE_NAME}((uuid::uuid))
      SQL
    end
  end

  def down
    remove_concurrent_index_by_name(
      TABLE_NAME,
      INDEX_NAME
    )
  end
end
