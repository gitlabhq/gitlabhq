# frozen_string_literal: true

class AddProjectIdToPackagesPackageFileStates < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def change
    add_column :packages_package_file_states, :project_id, :bigint
  end
end
