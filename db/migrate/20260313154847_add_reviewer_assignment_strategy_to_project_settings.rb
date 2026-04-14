# frozen_string_literal: true

class AddReviewerAssignmentStrategyToProjectSettings < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def change
    add_column :project_settings, :reviewer_assignment_strategy, :integer, limit: 2, default: 0, null: false
  end
end
