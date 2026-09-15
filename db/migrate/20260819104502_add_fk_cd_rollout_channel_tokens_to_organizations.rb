# frozen_string_literal: true

class AddFkCdRolloutChannelTokensToOrganizations < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.4'

  def up
    add_concurrent_foreign_key :cd_rollout_channel_tokens, :organizations,
      column: :organization_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :cd_rollout_channel_tokens, column: :organization_id
    end
  end
end
