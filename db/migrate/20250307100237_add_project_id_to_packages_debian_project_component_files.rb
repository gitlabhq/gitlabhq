# frozen_string_literal: true

class AddProjectIdToPackagesDebianProjectComponentFiles < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    add_column :packages_debian_project_component_files, :project_id, :bigint
  end
end
