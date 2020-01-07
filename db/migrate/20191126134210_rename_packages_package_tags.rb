# frozen_string_literal: true

class RenamePackagesPackageTags < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    rename_table(:packages_package_tags, :packages_tags)
  end
end
