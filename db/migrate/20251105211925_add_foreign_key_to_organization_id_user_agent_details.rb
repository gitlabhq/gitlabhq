# frozen_string_literal: true

class AddForeignKeyToOrganizationIdUserAgentDetails < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def up
    add_concurrent_foreign_key :user_agent_details, :organizations, column: :organization_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :user_agent_details, column: :organization_id
    end
  end
end
