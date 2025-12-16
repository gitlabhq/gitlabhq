# frozen_string_literal: true

class AddNotNullConstraintOnDependencyListExportUploadsShardingKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    add_multi_column_not_null_constraint(
      :dependency_list_export_uploads,
      :project_id, :namespace_id, :organization_id,
      operator: '>', limit: 0 # NOTE: reflecting the selection of the parent https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172178/diffs
    )
  end

  def down
    remove_multi_column_not_null_constraint(
      :dependency_list_export_uploads,
      :project_id, :namespace_id, :organization_id
    )
  end
end
