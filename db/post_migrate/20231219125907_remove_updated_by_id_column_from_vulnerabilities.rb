# frozen_string_literal: true

class RemoveUpdatedByIdColumnFromVulnerabilities < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.8'

  def up
    with_lock_retries do
      remove_column :vulnerabilities, :updated_by_id
    end
  end

  def down
    add_column :vulnerabilities, :updated_by_id, :bigint unless column_exists?(:vulnerabilities, :updated_by_id)

    # Add back index and constraint that were dropped in `up`
    add_concurrent_index(:vulnerabilities, :updated_by_id)
    add_concurrent_foreign_key(:vulnerabilities, :users, column: :updated_by_id, on_delete: :nullify)
  end
end
