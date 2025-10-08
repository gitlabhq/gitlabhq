# frozen_string_literal: true

class AddOrganizationIdToPoolRepositories < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def change
    add_column :pool_repositories, :organization_id, :bigint, null: true
  end
end
