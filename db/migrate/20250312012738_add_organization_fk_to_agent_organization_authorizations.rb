# frozen_string_literal: true

class AddOrganizationFkToAgentOrganizationAuthorizations < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  def up
    add_concurrent_foreign_key :agent_organization_authorizations, :organizations, column: :organization_id
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :agent_organization_authorizations, column: :organization_id
    end
  end
end
