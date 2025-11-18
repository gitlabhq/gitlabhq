# frozen_string_literal: true

class AddOrganizationIdToKeys < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.6'

  def change
    add_column :keys, :organization_id, :bigint
  end
end
