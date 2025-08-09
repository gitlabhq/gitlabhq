# frozen_string_literal: true

class AddOrganizationIdToLabels < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    add_column :labels, :organization_id, :bigint
  end
end
