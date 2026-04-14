# frozen_string_literal: true

class FkValidationForDeployments < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  FK_NAME = :fk_009fd21147_tmp
  TABLE_NAME = 'deployments'
  COLUMN = :environment_id

  def up
    return unless column_exists?(TABLE_NAME, convert_to_bigint_column(COLUMN))

    validate_foreign_key :deployments, :environment_id_convert_to_bigint, name: FK_NAME
  end

  def down
    # Can be safely a no-op if we don't roll back the inconsistent data.
  end
end
