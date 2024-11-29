# frozen_string_literal: true

class AddUpstreamPipelinePartitionIdToPCiBuilds < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    add_column :p_ci_builds, :upstream_pipeline_partition_id, :bigint # rubocop:disable Migration/PreventAddingColumns -- composable FK
  end
end
