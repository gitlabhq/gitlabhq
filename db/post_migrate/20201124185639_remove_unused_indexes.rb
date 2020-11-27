# frozen_string_literal: true

class RemoveUnusedIndexes < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :packages_package_files, "packages_packages_verification_failure_partial"
    remove_concurrent_index_by_name :packages_package_files, "packages_packages_verification_checksum_partial"
    remove_concurrent_index_by_name :snippet_repositories, 'snippet_repositories_verification_failure_partial'
    remove_concurrent_index_by_name :snippet_repositories, 'snippet_repositories_verification_checksum_partial'
    remove_concurrent_index_by_name :terraform_state_versions, 'terraform_state_versions_verification_failure_partial'
    remove_concurrent_index_by_name :terraform_state_versions, 'terraform_state_versions_verification_checksum_partial'
  end

  def down
    add_concurrent_index :packages_package_files, :verification_failure, where: "(verification_failure IS NOT NULL)", name: "packages_packages_verification_failure_partial"
    add_concurrent_index :packages_package_files, :verification_checksum, where: "(verification_checksum IS NOT NULL)", name: "packages_packages_verification_checksum_partial"
    add_concurrent_index :snippet_repositories, :verification_failure, where: "(verification_failure IS NOT NULL)", name: 'snippet_repositories_verification_failure_partial'
    add_concurrent_index :snippet_repositories, :verification_checksum, where: "(verification_checksum IS NOT NULL)", name: 'snippet_repositories_verification_checksum_partial'
    add_concurrent_index :terraform_state_versions, :verification_failure, where: "(verification_failure IS NOT NULL)", name: 'terraform_state_versions_verification_failure_partial'
    add_concurrent_index :terraform_state_versions, :verification_checksum, where: "(verification_checksum IS NOT NULL)", name: 'terraform_state_versions_verification_checksum_partial'
  end
end
