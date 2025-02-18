# frozen_string_literal: true

class UpdateImportFailuresOrganizationId < Gitlab::Database::Migration[2.2]
  DEFAULT_ORGANIZATION_ID = 1

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.9'

  def up
    define_batchable_model('import_failures')
      .where(organization_id: nil, project_id: nil, group_id: nil).each_batch(of: 10_000) do |batch|
      batch.update_all(
        organization_id: DEFAULT_ORGANIZATION_ID
      )
    end
  end

  def down
    # no-op
  end
end
