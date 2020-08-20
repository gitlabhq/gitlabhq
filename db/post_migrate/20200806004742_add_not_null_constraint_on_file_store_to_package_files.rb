# frozen_string_literal: true

class AddNotNullConstraintOnFileStoreToPackageFiles < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_not_null_constraint(:packages_package_files, :file_store, validate: false)
  end

  def down
    remove_not_null_constraint(:packages_package_files, :file_store)
  end
end
