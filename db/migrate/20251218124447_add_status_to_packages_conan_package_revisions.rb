# frozen_string_literal: true

class AddStatusToPackagesConanPackageRevisions < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  STATUS_DEFAULT = 0

  def change
    add_column :packages_conan_package_revisions, :status, :smallint, default: STATUS_DEFAULT, null: false
  end
end
