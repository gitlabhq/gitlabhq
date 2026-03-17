# frozen_string_literal: true

class ValidateFkDeploymentMergeRequestsToDeployments < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  TARGET_TABLE = "deployments"
  BIGINT_COLUMN = "id_convert_to_bigint"

  TABLE_NAME = "deployment_merge_requests"
  FK_NAME = "fk_dcbce9f4df_tmp"

  def up
    return unless column_exists?(TARGET_TABLE, BIGINT_COLUMN)

    validate_foreign_key TABLE_NAME, :deployment_id, name: FK_NAME
  end

  def down; end
end
