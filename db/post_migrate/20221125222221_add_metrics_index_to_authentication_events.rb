# frozen_string_literal: true

class AddMetricsIndexToAuthenticationEvents < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_successful_authentication_events_for_metrics'
  disable_ddl_transaction!

  def up
    add_concurrent_index :authentication_events,
      %i[user_id provider created_at],
      where: "result = 1",
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :authentication_events, INDEX_NAME
  end
end
