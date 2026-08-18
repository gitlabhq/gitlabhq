# frozen_string_literal: true

class FkValidationForDeploymentsPhaseTwo < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  FK_NAME = :fk_b9a3851b82_tmp
  TABLE_NAME = 'deployments'
  COLUMN = :project_id

  def up
    return unless column_exists?(TABLE_NAME, convert_to_bigint_column(COLUMN))

    validate_foreign_key :deployments, :project_id_convert_to_bigint, name: FK_NAME
  end

  def down
    # Can be safely a no-op if we don't roll back the inconsistent data.
  end
end
