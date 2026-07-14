# frozen_string_literal: true

class AddFkCdDeploymentTransitionsToOrganizations < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  def up
    add_concurrent_foreign_key :cd_deployment_transitions, :organizations,
      column: :organization_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :cd_deployment_transitions, column: :organization_id
    end
  end
end
