# frozen_string_literal: true

class AddProjectIdToPackagesPackageFileBuildInfos < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :packages_package_file_build_infos, :project_id, :bigint
  end
end
