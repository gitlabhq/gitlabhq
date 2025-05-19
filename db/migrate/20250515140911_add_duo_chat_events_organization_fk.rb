# frozen_string_literal: true

class AddDuoChatEventsOrganizationFk < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  disable_ddl_transaction!
  milestone '18.1'

  def up
    add_concurrent_partitioned_foreign_key :ai_duo_chat_events, :organizations, column: :organization_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :ai_duo_chat_events, column: :organization_id
    end
  end
end
