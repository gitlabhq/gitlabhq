# frozen_string_literal: true

class IndexProjectsOnIdNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  INDEX_NAME = 'index_projects_on_id_and_namespace_id'

  # rubocop:disable Migration/PreventIndexCreation -- This is part of an experiment to see if it improves certain queries
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/466236
  def up
    add_concurrent_index :projects, [:id, :namespace_id], name: INDEX_NAME
  end
  # rubocop:enable Migration/PreventIndexCreation

  def down
    remove_concurrent_index_by_name :projects, INDEX_NAME
  end
end
