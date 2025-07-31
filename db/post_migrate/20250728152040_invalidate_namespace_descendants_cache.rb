# frozen_string_literal: true

class InvalidateNamespaceDescendantsCache < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell
  milestone '18.3'

  class NamespaceDescendant < MigrationRecord
    include EachBatch

    self.table_name = 'namespace_descendants'
  end

  def up
    NamespaceDescendant.each_batch(of: 100) do |batch|
      batch.update_all("outdated_at = NOW()")
    end
  end
end
