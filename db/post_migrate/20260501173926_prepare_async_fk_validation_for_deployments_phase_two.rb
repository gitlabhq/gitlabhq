# frozen_string_literal: true

class PrepareAsyncFkValidationForDeploymentsPhaseTwo < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  TABLE_NAME = 'deployments'
  COLUMN = :project_id

  def up
    return unless column_exists?(TABLE_NAME, convert_to_bigint_column(COLUMN))

    prepare_async_foreign_key_validation(:deployments, :project_id_convert_to_bigint,
      name: :fk_b9a3851b82_tmp)
  end

  def down
    return unless column_exists?(TABLE_NAME, convert_to_bigint_column(COLUMN))

    unprepare_async_foreign_key_validation(:deployments, :project_id_convert_to_bigint,
      name: :fk_b9a3851b82_tmp)
  end
end
