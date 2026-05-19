# frozen_string_literal: true

class AddUniqueIndexOnAchievementUploadsId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.0'

  PARTITION_TABLE_NAME = :achievement_uploads
  PARTITION_INDEX_NAME = :index_achievement_uploads_on_id

  def up
    add_concurrent_index PARTITION_TABLE_NAME, :id, unique: true, name: PARTITION_INDEX_NAME, allow_partition: true
  end

  def down
    disable_statement_timeout do
      execute "DROP INDEX CONCURRENTLY IF EXISTS #{PARTITION_INDEX_NAME}"
    end
  end
end
