# frozen_string_literal: true

class AddStageEventHashesOrganizationIdIndex < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.2'

  INDEX = 'index_cycle_analytics_stage_event_hashes_on_org_id_sha_256'

  def up
    add_concurrent_index :analytics_cycle_analytics_stage_event_hashes, %i[organization_id hash_sha256], name: INDEX,
      unique: true
  end

  def down
    remove_concurrent_index_by_name :analytics_cycle_analytics_stage_event_hashes, name: INDEX
  end
end
