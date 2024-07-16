# frozen_string_literal: true

class AddProjectIdToPackagesDebianProjectComponents < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    add_column :packages_debian_project_components, :project_id, :bigint
  end
end
