# frozen_string_literal: true

class AddMergeRequestJiraReferenceIndexes < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  DESCRIPTION_INDEX_NAME = 'index_merge_requests_on_target_project_id_iid_jira_description'
  TITLE_INDEX_NAME = 'index_merge_requests_on_target_project_id_and_iid_jira_title'

  JIRA_KEY_REGEX = '[A-Z][A-Z_0-9]+-\d+'

  disable_ddl_transaction!

  def up
    add_concurrent_index(
      :merge_requests,
      [:target_project_id, :iid],
      name: TITLE_INDEX_NAME,
      using: :btree,
      where: "(merge_requests.title)::text ~ '#{JIRA_KEY_REGEX}'::text"
    )

    add_concurrent_index(
      :merge_requests,
      [:target_project_id, :iid],
      name: DESCRIPTION_INDEX_NAME,
      using: :btree,
      where: "(merge_requests.description)::text ~ '#{JIRA_KEY_REGEX}'::text"
    )
  end

  def down
    remove_concurrent_index_by_name(
      :merge_requests,
      TITLE_INDEX_NAME
    )

    remove_concurrent_index_by_name(
      :merge_requests,
      DESCRIPTION_INDEX_NAME
    )
  end
end
