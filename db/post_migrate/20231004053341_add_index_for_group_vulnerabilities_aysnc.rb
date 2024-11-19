# frozen_string_literal: true

class AddIndexForGroupVulnerabilitiesAysnc < Gitlab::Database::Migration[2.1]
  # The column used with the IN query and the columns in the ORDER BY
  # clause are covered with a database index. The columns in the index
  # must be in the following order: column_for_the_in_query, order by
  # column 1, and order by column 2.
  #
  # https://docs.gitlab.com/ee/development/database/efficient_in_operator_queries.html#requirements
  INDEX_NAME = 'index_vulnerabilities_on_project_id_and_id'
  TABLE_NAME = :vulnerabilities
  COLUMN_NAMES = [:project_id, :id]

  disable_ddl_transaction!

  def up
    # TODO: Issue for synchronous migration https://gitlab.com/gitlab-org/gitlab/-/issues/426371
    prepare_async_index :vulnerabilities, COLUMN_NAMES, name: INDEX_NAME # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
  end

  def down
    unprepare_async_index :vulnerabilities, COLUMN_NAMES, name: INDEX_NAME
  end
end
