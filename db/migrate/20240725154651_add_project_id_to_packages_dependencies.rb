# frozen_string_literal: true

class AddProjectIdToPackagesDependencies < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    add_column :packages_dependencies, :project_id, :bigint
  end
end
