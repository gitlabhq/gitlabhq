# frozen_string_literal: true

class AddNotNullToForkNetworksOrganizationId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '18.0'

  def up
    change_column_null :fork_networks, :organization_id, false
  end

  def down
    change_column_null :fork_networks, :organization_id, true
  end
end
