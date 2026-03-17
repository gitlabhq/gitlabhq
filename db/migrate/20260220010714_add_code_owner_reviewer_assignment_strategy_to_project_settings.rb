# frozen_string_literal: true

class AddCodeOwnerReviewerAssignmentStrategyToProjectSettings < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def change
    add_column :project_settings, :code_owner_reviewer_assignment_strategy, :integer, limit: 2, default: 0, null: false
  end
end
