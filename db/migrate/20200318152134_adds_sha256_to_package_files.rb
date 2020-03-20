# frozen_string_literal: true

class AddsSha256ToPackageFiles < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :packages_package_files, :file_sha256, :binary
  end
end
