# frozen_string_literal: true

class ReplaceIndexOnSecurityPolicySchedulePipelines < Gitlab::Database::Migration[2.3]
  milestone '19.1'
  disable_ddl_transaction!

  OLD_INDEX_NAME = 'idx_sec_pol_sched_pipes_on_policy_id'
  NEW_INDEX_NAME = 'idx_sec_pol_sched_pipes_on_policy_project_id_desc'

  def up
    add_concurrent_index :security_policy_schedule_pipelines,
      [:security_policy_id, :project_id, :id],
      order: { id: :desc },
      name: NEW_INDEX_NAME

    remove_concurrent_index_by_name :security_policy_schedule_pipelines, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :security_policy_schedule_pipelines,
      :security_policy_id,
      name: OLD_INDEX_NAME

    remove_concurrent_index_by_name :security_policy_schedule_pipelines, NEW_INDEX_NAME
  end
end
