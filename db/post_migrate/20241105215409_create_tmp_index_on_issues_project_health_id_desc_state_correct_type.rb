# frozen_string_literal: true

class CreateTmpIndexOnIssuesProjectHealthIdDescStateCorrectType < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_idx_issues_on_project_health_id_desc_state_correct_type'

  def up
    # Temporary index to be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/500165
    # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
    add_concurrent_index :issues, # -- Tmp index needed to fix work item type ids
      # rubocop:enable Migration/PreventIndexCreation
      [:project_id, :health_status, :id, :state_id, :correct_work_item_type_id],
      order: { health_status: 'DESC NULLS LAST', id: :desc },
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :issues, INDEX_NAME
  end
end
