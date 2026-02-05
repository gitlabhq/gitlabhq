# frozen_string_literal: true

class AsyncValidateFkJobEnvironmentsToDeployments < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  TARGET_TABLE = "deployments"
  BIGINT_COLUMN = "id_convert_to_bigint"

  FK_NAME = "fk_8729424205_tmp"

  def up
    return unless column_exists?(TARGET_TABLE, BIGINT_COLUMN)

    prepare_async_foreign_key_validation :job_environments, :deployment_id, name: FK_NAME
  end

  def down
    unprepare_async_foreign_key_validation :job_environments, :deployment_id, name: FK_NAME
  end
end
