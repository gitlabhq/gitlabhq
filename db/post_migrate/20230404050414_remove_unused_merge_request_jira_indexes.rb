# frozen_string_literal: true

class RemoveUnusedMergeRequestJiraIndexes < Gitlab::Database::Migration[2.1]
  TITLE_INDEX = {
    name: 'index_merge_requests_on_target_project_id_and_iid_jira_title',
    where: "((title)::text ~ '[A-Z][A-Z_0-9]+-\d+'::text)"
  }.freeze

  DESCRIPTION_INDEX = {
    name: 'index_merge_requests_on_target_project_id_iid_jira_description',
    where: "(description ~ '[A-Z][A-Z_0-9]+-\d+'::text)"
  }.freeze

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :merge_requests, name: TITLE_INDEX[:name]
    remove_concurrent_index_by_name :merge_requests, name: DESCRIPTION_INDEX[:name]
  end

  def down
    add_concurrent_index :merge_requests, [:target_project_id, :iid],
      where: TITLE_INDEX[:where],
      name: TITLE_INDEX[:name]
    add_concurrent_index :merge_requests, [:target_project_id, :iid],
      where: DESCRIPTION_INDEX[:where],
      name: DESCRIPTION_INDEX[:name]
  end
end
