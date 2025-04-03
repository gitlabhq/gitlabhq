# frozen_string_literal: true

class SetOrganizationIdForBulkImports < Gitlab::Database::Migration[2.2]
  DEFAULT_ORGANIZATION_ID = 1
  BATCH_SIZE = 2_500

  milestone '17.11'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    define_batchable_model('bulk_imports').where(organization_id: nil).each_batch(of: BATCH_SIZE) do |bulk_imports|
      bulk_imports.update_all(organization_id: DEFAULT_ORGANIZATION_ID)
    end
  end

  def down; end
end
