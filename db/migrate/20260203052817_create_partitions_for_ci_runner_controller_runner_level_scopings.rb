# frozen_string_literal: true

class CreatePartitionsForCiRunnerControllerRunnerLevelScopings < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  disable_ddl_transaction!

  milestone '18.9'

  def change
    create_list_partitions(
      'ci_runner_controller_runner_level_scopings',
      { instance_type: 1 },
      '%{table_name}_%{partition_name}'
    )
  end
end
