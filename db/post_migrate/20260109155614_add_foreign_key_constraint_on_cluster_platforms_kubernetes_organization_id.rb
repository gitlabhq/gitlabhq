# frozen_string_literal: true

class AddForeignKeyConstraintOnClusterPlatformsKubernetesOrganizationId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.9'

  TABLE_NAME = 'cluster_platforms_kubernetes'

  def up
    add_concurrent_foreign_key TABLE_NAME,
      :organizations,
      column: :organization_id,
      on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists TABLE_NAME, :organizations, column: :organization_id
  end
end
