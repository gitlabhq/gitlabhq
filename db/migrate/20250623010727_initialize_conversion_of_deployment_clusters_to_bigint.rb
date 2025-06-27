# frozen_string_literal: true

class InitializeConversionOfDeploymentClustersToBigint < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.2'

  TABLE = :deployment_clusters
  COLUMNS = %i[deployment_id cluster_id]

  def up
    initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    revert_initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
