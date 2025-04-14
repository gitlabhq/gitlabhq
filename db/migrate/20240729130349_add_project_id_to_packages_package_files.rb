# frozen_string_literal: true

class AddProjectIdToPackagesPackageFiles < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    # rubocop:disable Migration/PreventAddingColumns -- large tables
    add_column :packages_package_files, :project_id, :bigint
    # rubocop:enable Migration/PreventAddingColumns
  end
end
