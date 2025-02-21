# frozen_string_literal: true

class AddAiDuoChatEventsOrganizationIdIndex < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '17.10'

  INDEX_NAME = 'index_ai_duo_chat_events_on_organization_id'

  def up
    add_concurrent_partitioned_index :ai_duo_chat_events, :organization_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_partitioned_index_by_name :ai_duo_chat_events, INDEX_NAME
  end
end
