# frozen_string_literal: true

class AddCheckConstraintToPackagesDebianComponentFiles < Gitlab::Database::Migration[2.3]
  milestone '18.10'
  disable_ddl_transaction!

  GROUP_TABLE_NAME = :packages_debian_group_component_files
  PROJECT_TABLE_NAME = :packages_debian_project_component_files
  GROUP_FILE_SHA256_CONSTRAINT_NAME = 'check_debian_group_component_files_file_sha256_max_length'
  PROJECT_FILE_SHA256_CONSTRAINT_NAME = 'check_debian_project_component_files_file_sha256_max_length'

  def up
    add_check_constraint(
      GROUP_TABLE_NAME,
      'octet_length(file_sha256) <= 64',
      GROUP_FILE_SHA256_CONSTRAINT_NAME,
      validate: false
    )
    add_check_constraint(
      PROJECT_TABLE_NAME,
      'octet_length(file_sha256) <= 64',
      PROJECT_FILE_SHA256_CONSTRAINT_NAME,
      validate: false
    )
  end

  def down
    remove_check_constraint(
      GROUP_TABLE_NAME,
      GROUP_FILE_SHA256_CONSTRAINT_NAME
    )
    remove_check_constraint(
      PROJECT_TABLE_NAME,
      PROJECT_FILE_SHA256_CONSTRAINT_NAME
    )
  end
end
