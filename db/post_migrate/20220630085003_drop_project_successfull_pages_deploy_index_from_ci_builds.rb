# frozen_string_literal: true

class DropProjectSuccessfullPagesDeployIndexFromCiBuilds < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_builds_on_project_id_for_successfull_pages_deploy'

  def up
    remove_concurrent_index_by_name :ci_builds, INDEX_NAME
  end

  # rubocop:disable Migration/PreventIndexCreation
  def down
    add_concurrent_index :ci_builds,
      :project_id,
      where: "(((type)::text = 'GenericCommitStatus'::text) AND ((stage)::text = 'deploy'::text) AND " \
             "((name)::text = 'pages:deploy'::text) AND ((status)::text = 'success'::text))",
      name: INDEX_NAME
  end
  # rubocop:enable Migration/PreventIndexCreation
end
