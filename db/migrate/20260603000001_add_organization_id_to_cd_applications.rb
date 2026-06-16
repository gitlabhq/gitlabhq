# frozen_string_literal: true

class AddOrganizationIdToCdApplications < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def change
    add_column :cd_applications, :organization_id, :bigint
  end
end
