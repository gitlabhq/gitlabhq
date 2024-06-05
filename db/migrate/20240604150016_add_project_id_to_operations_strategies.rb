# frozen_string_literal: true

class AddProjectIdToOperationsStrategies < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :operations_strategies, :project_id, :bigint
  end
end
