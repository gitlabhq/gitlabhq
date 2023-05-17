# frozen_string_literal: true

class RemoveIndexOnEventsAction < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    remove_concurrent_index :events, :action, name: 'index_events_on_action'
  end

  def down
    add_concurrent_index :events, :action, name: 'index_events_on_action'
  end
end
