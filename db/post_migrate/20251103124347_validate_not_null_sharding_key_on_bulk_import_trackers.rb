# frozen_string_literal: true

class ValidateNotNullShardingKeyOnBulkImportTrackers < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  CONSTRAINT_NAME = :check_5f034e7cad

  def up
    # NOTE: follow up to https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188587
    validate_multi_column_not_null_constraint(
      :bulk_import_trackers,
      :organization_id, :namespace_id, :project_id,
      constraint_name: CONSTRAINT_NAME
    )
  end

  def down
    # no-op
  end
end
