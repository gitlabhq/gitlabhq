# frozen_string_literal: true

class AddRootDirectoryToPagesDeployment < Gitlab::Database::Migration[2.1]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20230323140746_add_text_limit_to_pages_deployment_root_directory
  def change
    add_column :pages_deployments, :root_directory, :text, default: "public"
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
