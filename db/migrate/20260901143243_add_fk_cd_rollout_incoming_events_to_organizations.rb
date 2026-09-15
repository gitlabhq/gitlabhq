# frozen_string_literal: true

class AddFkCdRolloutIncomingEventsToOrganizations < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.4'

  def up
    add_concurrent_foreign_key :cd_rollout_incoming_events, :organizations,
      column: :organization_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :cd_rollout_incoming_events, column: :organization_id
    end
  end
end
