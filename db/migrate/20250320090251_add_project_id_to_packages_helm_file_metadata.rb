# frozen_string_literal: true

class AddProjectIdToPackagesHelmFileMetadata < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :packages_helm_file_metadata, :project_id, :bigint
  end
end
