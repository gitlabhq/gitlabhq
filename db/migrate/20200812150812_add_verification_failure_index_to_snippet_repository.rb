# frozen_string_literal: true

class AddVerificationFailureIndexToSnippetRepository < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :snippet_repositories, :verification_failure, where: "(verification_failure IS NOT NULL)", name: 'snippet_repositories_verification_failure_partial'
    add_concurrent_index :snippet_repositories, :verification_checksum, where: "(verification_checksum IS NOT NULL)", name: 'snippet_repositories_verification_checksum_partial'
  end

  def down
    remove_concurrent_index_by_name :snippet_repositories, 'snippet_repositories_verification_failure_partial'
    remove_concurrent_index_by_name :snippet_repositories, 'snippet_repositories_verification_checksum_partial'
  end
end
