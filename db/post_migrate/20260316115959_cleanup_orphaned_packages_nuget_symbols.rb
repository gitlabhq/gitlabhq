# frozen_string_literal: true

class CleanupOrphanedPackagesNugetSymbols < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.11'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  BATCH_SIZE = 1000

  def up
    relation = define_batchable_model('packages_nuget_symbols')

    loop do
      batch = relation.where(<<~SQL).limit(BATCH_SIZE)
        NOT EXISTS (
          SELECT 1 FROM projects
          WHERE projects.id = packages_nuget_symbols.project_id
        )
      SQL
      delete_count = relation.where(id: batch.select(:id)).delete_all

      break if delete_count == 0
    end
  end

  def down
    # deleted data cannot be restored
  end
end
