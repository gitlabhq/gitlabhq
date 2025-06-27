# frozen_string_literal: true

class AddOrganizationIdToForkNetworks < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    add_column :fork_networks, :organization_id, :bigint, null: true
  end
end
