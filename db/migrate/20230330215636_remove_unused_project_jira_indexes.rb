# frozen_string_literal: true

class RemoveUnusedProjectJiraIndexes < Gitlab::Database::Migration[2.1]
  TITLE_INDEX = {
    name: 'index_merge_requests_on_target_project_id_and_iid_jira_title',
    where: "((title)::text ~ '[A-Z][A-Z_0-9]+-\d+'::text)"
  }.freeze

  DESCRIPTION_INDEX = {
    name: 'index_merge_requests_on_target_project_id_iid_jira_description',
    where: "(description ~ '[A-Z][A-Z_0-9]+-\d+'::text)"
  }.freeze

  # TODO: Indexes to be destroyed synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/403327
  def up
    prepare_async_index_removal :merge_requests, [:target_project_id, :iid],
      where: TITLE_INDEX[:where],
      name: TITLE_INDEX[:name]

    prepare_async_index_removal :merge_requests, [:target_project_id, :iid],
      where: DESCRIPTION_INDEX[:where],
      name: DESCRIPTION_INDEX[:name]
  end

  def down
    unprepare_async_index :merge_requests, [:target_project_id, :iid],
      where: TITLE_INDEX[:where],
      name: TITLE_INDEX[:name]

    unprepare_async_index :merge_requests, [:target_project_id, :iid],
      where: DESCRIPTION_INDEX[:where],
      name: DESCRIPTION_INDEX[:name]
  end
end
