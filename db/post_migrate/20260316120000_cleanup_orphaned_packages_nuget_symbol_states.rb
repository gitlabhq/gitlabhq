# frozen_string_literal: true

class CleanupOrphanedPackagesNugetSymbolStates < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.11'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  BATCH_SIZE = 1000

  def up
    relation = define_batchable_model('packages_nuget_symbol_states')

    loop do
      batch = relation.where(<<~SQL).limit(BATCH_SIZE)
        NOT EXISTS (
          SELECT 1 FROM packages_nuget_symbols
          WHERE packages_nuget_symbols.id = packages_nuget_symbol_states.packages_nuget_symbol_id
        )
      SQL
      delete_count = relation.where(id: batch.select(:id)).delete_all

      break if delete_count == 0
    end

    loop do
      batch = relation.where(<<~SQL).limit(BATCH_SIZE)
        packages_nuget_symbol_id IN (
          SELECT id FROM packages_nuget_symbols
          WHERE NOT EXISTS (
            SELECT 1 FROM projects
            WHERE projects.id = packages_nuget_symbols.project_id
          )
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
