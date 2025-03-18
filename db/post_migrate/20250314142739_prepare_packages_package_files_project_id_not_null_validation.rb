# frozen_string_literal: true

class PreparePackagesPackageFilesProjectIdNotNullValidation < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  CONSTRAINT_NAME = :check_43773f06dc

  def up
    prepare_async_check_constraint_validation :packages_package_files, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :packages_package_files, name: CONSTRAINT_NAME
  end
end
