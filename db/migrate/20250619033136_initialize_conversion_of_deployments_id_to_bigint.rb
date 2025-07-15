# frozen_string_literal: true

class InitializeConversionOfDeploymentsIdToBigint < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.2'

  TABLE = :deployments
  COLUMNS = %i[id environment_id project_id user_id]

  def up
    initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    revert_initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
