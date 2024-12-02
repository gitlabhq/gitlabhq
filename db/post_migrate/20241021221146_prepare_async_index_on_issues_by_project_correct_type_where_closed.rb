# frozen_string_literal: true

class PrepareAsyncIndexOnIssuesByProjectCorrectTypeWhereClosed < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  INDEX_NAME = 'tmp_idx_issues_on_project_correct_type_closed_at_where_closed'

  def up
    # Temporary index to be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/500165
    # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170005
    prepare_async_index :issues, # -- Tmp index needed to fix work item type ids
      [:project_id, :correct_work_item_type_id, :closed_at],
      where: 'state_id = 2',
      name: INDEX_NAME
  end

  def down
    unprepare_async_index_by_name :issues, INDEX_NAME
  end
end
