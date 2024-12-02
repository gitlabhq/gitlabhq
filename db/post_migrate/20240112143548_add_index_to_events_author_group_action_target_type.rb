# frozen_string_literal: true

class AddIndexToEventsAuthorGroupActionTargetType < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  disable_ddl_transaction!

  INDEX_NAME = 'index_events_author_id_group_id_action_target_type_created_at'
  COLUMNS = [:author_id, :group_id, :action, :target_type, :created_at]

  def up
    add_concurrent_index :events, COLUMNS, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :events, INDEX_NAME
  end
end
