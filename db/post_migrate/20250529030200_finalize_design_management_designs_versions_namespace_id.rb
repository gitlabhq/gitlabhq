# frozen_string_literal: true

class FinalizeDesignManagementDesignsVersionsNamespaceId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '18.1'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillDesignManagementDesignsVersionsNamespaceId',
      table_name: :design_management_designs_versions,
      column_name: :id,
      job_arguments: [
        :namespace_id,
        :design_management_designs,
        :namespace_id,
        :design_id
      ],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
