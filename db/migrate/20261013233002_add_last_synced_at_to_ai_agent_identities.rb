# frozen_string_literal: true

class AddLastSyncedAtToAiAgentIdentities < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  def change
    add_column :ai_agent_identities, :last_synced_at, :datetime_with_timezone
  end
end
