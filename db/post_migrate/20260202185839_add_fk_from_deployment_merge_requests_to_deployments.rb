# frozen_string_literal: true

class AddFkFromDeploymentMergeRequestsToDeployments < Gitlab::Database::Migration[2.3]
  milestone '18.9'
  disable_ddl_transaction!

  TARGET_TABLE = "deployments"
  BIGINT_COLUMN = "id_convert_to_bigint"
  FK_NAME = "fk_dcbce9f4df_tmp"

  TABLE_NAME = "deployment_merge_requests"

  def up
    return unless column_exists?(TARGET_TABLE, BIGINT_COLUMN)

    add_concurrent_foreign_key TABLE_NAME,
      TARGET_TABLE,
      column: :deployment_id,
      target_column: BIGINT_COLUMN,
      on_delete: :cascade,
      validate: false,
      reverse_lock_order: true,
      name: FK_NAME
  end

  def down
    remove_foreign_key_if_exists TABLE_NAME,
      TARGET_TABLE,
      column: :deployment_id,
      target_column: BIGINT_COLUMN,
      reverse_lock_order: true,
      name: FK_NAME
  end
end
