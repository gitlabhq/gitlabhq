# frozen_string_literal: true

class ReplaceIssuesMilestoneIndex < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  INDEX_NAME = 'index_issues_on_milestone_id_and_id'

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/461627
  # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
  def up
    prepare_async_index :issues, %i[milestone_id id], name: INDEX_NAME
  end
  # rubocop:enable Migration/PreventIndexCreation

  def down
    unprepare_async_index :issues, %i[milestone_id id], name: INDEX_NAME
  end
end
