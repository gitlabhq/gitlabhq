# frozen_string_literal: true

class AddProjectIdToPackagesPackageFiles < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    add_column :packages_package_files, :project_id, :bigint
  end
end
