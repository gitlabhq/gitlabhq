# frozen_string_literal: true

class AddIndexOnProjectUploadsProjectIdAndId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.1'

  TABLE_NAME = :project_uploads
  INDEX_NAME = :index_project_uploads_on_project_id_and_id

  def up
    # rubocop:disable Migration/PreventIndexCreation -- https://gitlab.com/gitlab-org/database-team/team-tasks/-/work_items/640
    add_concurrent_index TABLE_NAME, [:project_id, :id], name: INDEX_NAME, allow_partition: true
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    disable_statement_timeout do
      execute "DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME}"
    end
  end
end
