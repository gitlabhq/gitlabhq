# frozen_string_literal: true

class RemoveMilestoneIdColumnFromVulnerabilities < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.8'

  def up
    with_lock_retries do
      remove_column :vulnerabilities, :milestone_id
    end
  end

  def down
    add_column :vulnerabilities, :milestone_id, :bigint unless column_exists?(:vulnerabilities, :milestone_id)

    # Add back index and constraint that were dropped in `up`
    add_concurrent_index(:vulnerabilities, :milestone_id)
    add_concurrent_foreign_key(:vulnerabilities, :milestones, column: :milestone_id, on_delete: :nullify)
  end
end
