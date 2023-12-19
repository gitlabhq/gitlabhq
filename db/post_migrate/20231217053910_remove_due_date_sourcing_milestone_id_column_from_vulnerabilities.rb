# frozen_string_literal: true

class RemoveDueDateSourcingMilestoneIdColumnFromVulnerabilities < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.8'

  def up
    with_lock_retries do
      remove_column :vulnerabilities, :due_date_sourcing_milestone_id
    end
  end

  def down
    unless column_exists?(:vulnerabilities, :due_date_sourcing_milestone_id)
      add_column :vulnerabilities, :due_date_sourcing_milestone_id, :bigint
    end

    # Add back index and constraint that were dropped in `up`
    add_concurrent_index(:vulnerabilities, :due_date_sourcing_milestone_id)
    add_concurrent_foreign_key(:vulnerabilities, :milestones, column: :due_date_sourcing_milestone_id,
      on_delete: :nullify)
  end
end
