# frozen_string_literal: true

class AddNotNullOrganizationIdOnForkNetworks < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  def up
    change_column_null :fork_networks, :organization_id, false
  end

  def down
    change_column_null :fork_networks, :organization_id, true
  end
end
