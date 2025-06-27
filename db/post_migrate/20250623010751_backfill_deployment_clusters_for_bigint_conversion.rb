# frozen_string_literal: true

class BackfillDeploymentClustersForBigintConversion < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '18.2'

  TABLE = :deployment_clusters
  COLUMNS = %i[deployment_id cluster_id]

  def up
    backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS, primary_key: :deployment_id, sub_batch_size: 200)
  end

  def down
    revert_backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS, primary_key: :deployment_id)
  end
end
