# frozen_string_literal: true

class AddCheckConstraintPackagesPackageFilesByteaColumnsLength < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  disable_ddl_transaction!

  TABLE_NAME = :packages_package_files
  CONSTRAINT_NAME_FILE_MD5 = 'check_package_files_file_md5_max_length'
  CONSTRAINT_NAME_FILE_SHA1 = 'check_package_files_file_sha1_max_length'
  CONSTRAINT_NAME_FILE_SHA256 = 'check_package_files_file_sha256_max_length'

  def up
    add_check_constraint(TABLE_NAME, 'octet_length(file_md5) <= 32', CONSTRAINT_NAME_FILE_MD5, validate: false)
    add_check_constraint(TABLE_NAME, 'octet_length(file_sha1) <= 40', CONSTRAINT_NAME_FILE_SHA1, validate: false)
    add_check_constraint(TABLE_NAME, 'octet_length(file_sha256) <= 64', CONSTRAINT_NAME_FILE_SHA256, validate: false)
  end

  def down
    remove_check_constraint(TABLE_NAME, CONSTRAINT_NAME_FILE_MD5)
    remove_check_constraint(TABLE_NAME, CONSTRAINT_NAME_FILE_SHA1)
    remove_check_constraint(TABLE_NAME, CONSTRAINT_NAME_FILE_SHA256)
  end
end
