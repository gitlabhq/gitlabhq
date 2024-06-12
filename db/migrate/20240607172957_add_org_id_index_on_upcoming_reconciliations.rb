# frozen_string_literal: true

class AddOrgIdIndexOnUpcomingReconciliations < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  disable_ddl_transaction!

  INDEX = 'index_upcoming_reconciliations_on_organization_id'

  def up
    add_concurrent_index :upcoming_reconciliations,
      %i[organization_id],
      name: INDEX
  end

  def down
    remove_concurrent_index_by_name :upcoming_reconciliations, name: INDEX
  end
end
