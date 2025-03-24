# frozen_string_literal: true

class AddFkForPartitionedUploadsOrganizationId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  milestone '17.11'

  disable_ddl_transaction!

  def up
    add_concurrent_partitioned_foreign_key :uploads_9ba88c4165, :organizations, column: :organization_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :uploads_9ba88c4165, column: :organization_id
    end
  end
end
