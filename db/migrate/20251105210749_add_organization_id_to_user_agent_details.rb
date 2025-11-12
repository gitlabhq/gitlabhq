# frozen_string_literal: true

class AddOrganizationIdToUserAgentDetails < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def change
    add_column :user_agent_details, :organization_id, :bigint
  end
end
