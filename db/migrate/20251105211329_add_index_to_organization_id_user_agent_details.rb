# frozen_string_literal: true

class AddIndexToOrganizationIdUserAgentDetails < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  INDEX_NAME = 'index_user_agent_details_on_organization_id'

  def up
    add_concurrent_index :user_agent_details, :organization_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :user_agent_details, :organization_id, name: INDEX_NAME
  end
end
