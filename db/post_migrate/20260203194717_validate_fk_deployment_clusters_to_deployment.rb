# frozen_string_literal: true

class ValidateFkDeploymentClustersToDeployment < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  TARGET_TABLE = "deployment_clusters"
  BIGINT_COLUMN = "deployment_id_convert_to_bigint"

  FK_NAME = :fk_rails_6359a164df_tmp

  def up
    return unless column_exists?(TARGET_TABLE, BIGINT_COLUMN)

    validate_foreign_key TARGET_TABLE, BIGINT_COLUMN, name: FK_NAME
  end

  def down
    # Can be safely a no-op if we don't roll back the inconsistent data.
  end
end
