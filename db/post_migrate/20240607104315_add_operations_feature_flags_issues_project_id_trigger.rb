# frozen_string_literal: true

class AddOperationsFeatureFlagsIssuesProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def up
    install_sharding_key_assignment_trigger(
      table: :operations_feature_flags_issues,
      sharding_key: :project_id,
      parent_table: :operations_feature_flags,
      parent_sharding_key: :project_id,
      foreign_key: :feature_flag_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :operations_feature_flags_issues,
      sharding_key: :project_id,
      parent_table: :operations_feature_flags,
      parent_sharding_key: :project_id,
      foreign_key: :feature_flag_id
    )
  end
end
