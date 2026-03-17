# frozen_string_literal: true

class ValidateFkJobEnvironmentsToDeployments < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  TARGET_TABLE = "deployments"
  BIGINT_COLUMN = "id_convert_to_bigint"

  TABLE_NAME = "job_environments"
  FK_NAME = "fk_8729424205_tmp"

  def up
    return unless column_exists?(TARGET_TABLE, BIGINT_COLUMN)

    validate_foreign_key TABLE_NAME, :deployment_id, name: FK_NAME
  end

  def down; end
end
