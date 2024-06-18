# frozen_string_literal: true

class AddPartitionIdToSourcesProjects < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column(:ci_sources_projects, :partition_id, :bigint, default: 100, null: false)
  end
end
