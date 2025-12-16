# frozen_string_literal: true

class AddForeignKeysToSlackIntegrationScopesGroupId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    add_concurrent_foreign_key :slack_integrations_scopes, :namespaces, column: :group_id
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :slack_integrations_scopes, column: :group_id
    end
  end
end
