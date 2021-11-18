# frozen_string_literal: true

class RemoveRedundantEventsIndex < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :events, :index_events_on_target_type_and_target_id
  end

  def down
    add_concurrent_index :events, [:target_type, :target_id], name: :index_events_on_target_type_and_target_id
  end
end
