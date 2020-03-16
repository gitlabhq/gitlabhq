# frozen_string_literal: true

class RemoveFileTypeFromPackagesPackageFiles < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    remove_column :packages_package_files, :file_type, :integer
  end
end
