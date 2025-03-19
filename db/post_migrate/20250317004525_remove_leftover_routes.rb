# frozen_string_literal: true

class RemoveLeftoverRoutes < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.11'

  class DeletedRecord < MigrationRecord
    self.table_name = 'loose_foreign_keys_deleted_records'

    include EachBatch
  end

  class Route < MigrationRecord
  end

  def up
    DeletedRecord
      .where(fully_qualified_table_name: 'public.namespaces', status: 1)
      .each_batch(column: :id) do |records|
      Route.where(namespace_id: records.pluck(:primary_key_value)).delete_all
    end
  end

  def down
    # no-op
  end
end
