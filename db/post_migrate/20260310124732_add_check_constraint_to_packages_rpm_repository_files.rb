# frozen_string_literal: true

class AddCheckConstraintToPackagesRpmRepositoryFiles < Gitlab::Database::Migration[2.3]
  milestone '18.11'
  disable_ddl_transaction!

  TABLE_NAME = :packages_rpm_repository_files
  FILE_MD5_CONSTRAINT_NAME = 'check_packages_rpm_repository_files_file_md5_max_length'
  FILE_SHA1_CONSTRAINT_NAME = 'check_packages_rpm_repository_files_file_sha1_max_length'
  FILE_SHA256_CONSTRAINT_NAME = 'check_packages_rpm_repository_files_file_sha256_max_length'

  # These constraints are added with `validate: false` intentionally.
  # There is no plan to fix existing invalid data.
  # The purpose is solely to prevent invalid data from being inserted in the future.
  def up
    add_check_constraint(TABLE_NAME, 'octet_length(file_md5) <= 32', FILE_MD5_CONSTRAINT_NAME, validate: false)
    add_check_constraint(TABLE_NAME, 'octet_length(file_sha1) <= 40', FILE_SHA1_CONSTRAINT_NAME, validate: false)
    add_check_constraint(TABLE_NAME, 'octet_length(file_sha256) <= 64', FILE_SHA256_CONSTRAINT_NAME, validate: false)
  end

  def down
    remove_check_constraint(TABLE_NAME, FILE_MD5_CONSTRAINT_NAME)
    remove_check_constraint(TABLE_NAME, FILE_SHA1_CONSTRAINT_NAME)
    remove_check_constraint(TABLE_NAME, FILE_SHA256_CONSTRAINT_NAME)
  end
end
