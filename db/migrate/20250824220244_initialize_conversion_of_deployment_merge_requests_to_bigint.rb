# frozen_string_literal: true

class InitializeConversionOfDeploymentMergeRequestsToBigint < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  TABLE = :deployment_merge_requests
  COLUMNS = %i[deployment_id merge_request_id environment_id]

  def up
    initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    revert_initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
