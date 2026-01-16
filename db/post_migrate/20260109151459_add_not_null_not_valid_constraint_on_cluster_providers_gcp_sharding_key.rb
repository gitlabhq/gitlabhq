# frozen_string_literal: true

class AddNotNullNotValidConstraintOnClusterProvidersGcpShardingKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.9'

  TABLE_NAME = 'cluster_providers_gcp'

  def up
    add_multi_column_not_null_constraint(
      TABLE_NAME,
      :organization_id, :group_id, :project_id,
      validate: false
    )
  end

  def down
    remove_multi_column_not_null_constraint(
      TABLE_NAME,
      :organization_id, :group_id, :project_id
    )
  end
end
