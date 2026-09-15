# frozen_string_literal: true

class AddIndexOnStageEventHashesOrganizationIdAndId < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  TABLE_NAME = :analytics_cycle_analytics_stage_event_hashes
  INDEX_NAME = 'index_cycle_analytics_stage_event_hashes_on_org_id_and_id'

  def up
    add_concurrent_index TABLE_NAME, [:organization_id, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
