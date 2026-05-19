# frozen_string_literal: true

class RemoveCodeOwnerReviewerAssignmentStrategyFromProjectSettings < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def up
    with_lock_retries do
      remove_column :project_settings, :code_owner_reviewer_assignment_strategy, if_exists: true
    end
  end

  def down
    add_column :project_settings, :code_owner_reviewer_assignment_strategy, :integer,
      limit: 2, default: 0, null: false, if_not_exists: true
  end
end
