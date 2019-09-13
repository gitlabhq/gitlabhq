# frozen_string_literal: true

class ReplaceEventsIndexOnGroupIdWithPartialIndex < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:events, :group_id, where: 'group_id IS NOT NULL', name: 'index_events_on_group_id_partial')
    remove_concurrent_index_by_name(:events, 'index_events_on_group_id')
  end

  def down
    add_concurrent_index(:events, :group_id, name: 'index_events_on_group_id')
    remove_concurrent_index_by_name(:events, 'index_events_on_group_id_partial')
  end
end
