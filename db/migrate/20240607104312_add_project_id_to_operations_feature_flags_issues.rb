# frozen_string_literal: true

class AddProjectIdToOperationsFeatureFlagsIssues < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :operations_feature_flags_issues, :project_id, :bigint
  end
end
