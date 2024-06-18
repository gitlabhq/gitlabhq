# frozen_string_literal: true

class AddOperationsStrategiesUserListsProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def up
    install_sharding_key_assignment_trigger(
      table: :operations_strategies_user_lists,
      sharding_key: :project_id,
      parent_table: :operations_user_lists,
      parent_sharding_key: :project_id,
      foreign_key: :user_list_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :operations_strategies_user_lists,
      sharding_key: :project_id,
      parent_table: :operations_user_lists,
      parent_sharding_key: :project_id,
      foreign_key: :user_list_id
    )
  end
end
