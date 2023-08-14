# frozen_string_literal: true

class AddIndexToPathPrefixAndBuildRefToPagesDeployments < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = :pages_deployments
  INDEX_NAME = 'index_pages_deployments_unique_path_prefix_by_project'

  def up
    add_text_limit TABLE_NAME, :path_prefix, 128
    add_text_limit TABLE_NAME, :build_ref, 512

    add_concurrent_index TABLE_NAME,
      [:project_id, :path_prefix],
      name: INDEX_NAME,
      unique: true
  end

  def down
    remove_text_limit TABLE_NAME, :path_prefix
    remove_text_limit TABLE_NAME, :build_ref

    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
