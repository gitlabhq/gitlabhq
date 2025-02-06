# frozen_string_literal: true

class AddOperationsScopesProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def up
    install_sharding_key_assignment_trigger(
      table: :operations_scopes,
      sharding_key: :project_id,
      parent_table: :operations_strategies,
      parent_sharding_key: :project_id,
      foreign_key: :strategy_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :operations_scopes,
      sharding_key: :project_id,
      parent_table: :operations_strategies,
      parent_sharding_key: :project_id,
      foreign_key: :strategy_id
    )
  end
end
