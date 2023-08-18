# frozen_string_literal: true

class AddPathPrefixAndBuildRefToPagesDeployments < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20230809165213_add_index_to_path_prefix_and_ref_to_pages_deployments
  def change
    add_column :pages_deployments, :path_prefix, :text
    add_column :pages_deployments, :build_ref, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
