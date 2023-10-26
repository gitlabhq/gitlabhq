# frozen_string_literal: true

class RemoveRedundantGroupStagesIndex < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.6'

  INDEX_NAME = 'index_analytics_ca_group_stages_on_group_id'

  def up
    remove_concurrent_index_by_name(:analytics_cycle_analytics_group_stages, INDEX_NAME)
  end

  def down
    add_concurrent_index(:analytics_cycle_analytics_group_stages, :group_id, name: INDEX_NAME)
  end
end
