# frozen_string_literal: true

class AddUniqueIndexOnOrganizationDetailUploadsId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.2'

  PARTITION_TABLE_NAME = :organization_detail_uploads
  PARTITION_INDEX_NAME = :idx_organization_detail_uploads_on_id

  def up
    add_concurrent_index PARTITION_TABLE_NAME, :id, unique: true, name: PARTITION_INDEX_NAME, allow_partition: true
  end

  def down
    execute "DROP INDEX CONCURRENTLY IF EXISTS #{PARTITION_INDEX_NAME}"
  end
end
