# frozen_string_literal: true

class AddAiUsageEventsNamespaceFk < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  disable_ddl_transaction!
  milestone '18.2'

  def change
    add_concurrent_partitioned_foreign_key :ai_usage_events, :namespaces, column: :namespace_id, on_delete: :nullify
  end
end
