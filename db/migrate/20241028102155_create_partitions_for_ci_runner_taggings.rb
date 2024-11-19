# frozen_string_literal: true

class CreatePartitionsForCiRunnerTaggings < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  milestone '17.6'

  def change
    create_list_partitions(
      'ci_runner_taggings',
      { instance_type: 1, group_type: 2, project_type: 3 },
      '%{table_name}_%{partition_name}')
  end
end
