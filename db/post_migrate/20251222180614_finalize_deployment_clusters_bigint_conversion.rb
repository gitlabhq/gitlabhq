# frozen_string_literal: true

class FinalizeDeploymentClustersBigintConversion < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '18.8'

  COLUMNS = %i[deployment_id cluster_id].freeze

  def up
    ensure_backfill_conversion_of_integer_to_bigint_is_finished(
      'deployment_clusters',
      COLUMNS,
      primary_key: :deployment_id
    )
  end

  def down; end
end
