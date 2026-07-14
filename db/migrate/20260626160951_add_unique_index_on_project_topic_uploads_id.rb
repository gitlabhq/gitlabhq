# frozen_string_literal: true

class AddUniqueIndexOnProjectTopicUploadsId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.2'

  PARTITION_TABLE_NAME = :project_topic_uploads
  PARTITION_INDEX_NAME = :idx_project_topic_uploads_on_id

  def up
    add_concurrent_index PARTITION_TABLE_NAME, :id, unique: true, name: PARTITION_INDEX_NAME, allow_partition: true
  end

  def down
    execute "DROP INDEX CONCURRENTLY IF EXISTS #{PARTITION_INDEX_NAME}"
  end
end
