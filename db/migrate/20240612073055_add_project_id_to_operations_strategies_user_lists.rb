# frozen_string_literal: true

class AddProjectIdToOperationsStrategiesUserLists < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :operations_strategies_user_lists, :project_id, :bigint
  end
end
