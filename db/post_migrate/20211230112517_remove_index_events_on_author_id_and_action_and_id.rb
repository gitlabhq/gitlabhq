# frozen_string_literal: true

class RemoveIndexEventsOnAuthorIdAndActionAndId < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_events_on_author_id_and_action_and_id'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :events, name: INDEX_NAME
  end

  def down
    # no-op
    # The index had been added in the same milestone.
    # Adding back the index takes a long time and should not be needed.
  end
end
