# frozen_string_literal: true

class SetOrganizationIdForBulkImportEntities < Gitlab::Database::Migration[2.2]
  DEFAULT_ORGANIZATION_ID = 1
  BATCH_SIZE = 2_500

  milestone '17.7'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  class BulkImportEntity < MigrationRecord; end

  def up
    define_batchable_model('bulk_import_entities').each_batch(of: BATCH_SIZE) do |bulk_import_entities|
      cte = Gitlab::SQL::CTE.new(:batched_relation, bulk_import_entities.limit(BATCH_SIZE))

      scope = cte.apply_to(BulkImportEntity.all).where(namespace_id: nil, project_id: nil, organization_id: nil)

      BulkImportEntity.where(id: scope.select(:id)).update_all(organization_id: DEFAULT_ORGANIZATION_ID)
    end
  end

  def down; end
end
