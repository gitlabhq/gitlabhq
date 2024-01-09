# frozen_string_literal: true

class RemoveEpicIdColumnFromVulnerabilities < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.8'

  def up
    with_lock_retries do
      remove_column :vulnerabilities, :epic_id
    end
  end

  def down
    add_column :vulnerabilities, :epic_id, :bigint unless column_exists?(:vulnerabilities, :epic_id)

    # Add back index and constraint that were dropped in `up`
    add_concurrent_index(:vulnerabilities, :epic_id)
    add_concurrent_foreign_key(:vulnerabilities, :epics, column: :epic_id, on_delete: :nullify)
  end
end
