# frozen_string_literal: true

class PrepareAsyncFkValidationForDeployments < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  TABLE_NAME = 'deployments'
  COLUMN = :environment_id

  def up
    return unless column_exists?(TABLE_NAME, convert_to_bigint_column(COLUMN))

    prepare_async_foreign_key_validation(:deployments, :environment_id_convert_to_bigint,
      name: :fk_009fd21147_tmp)
  end

  def down
    return unless column_exists?(TABLE_NAME, convert_to_bigint_column(COLUMN))

    unprepare_async_foreign_key_validation(:deployments, :environment_id_convert_to_bigint,
      name: :fk_009fd21147_tmp)
  end
end
