# frozen_string_literal: true

class AddRunnerTokensIndexes < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  # It seems that `ci_runners.token_encrypted` and `projects.runners_token_encrypted`
  # are non-unique

  def up
    add_concurrent_index :ci_runners, :token_encrypted
    add_concurrent_index :projects, :runners_token_encrypted
    add_concurrent_index :namespaces, :runners_token_encrypted, unique: true
  end

  def down
    remove_concurrent_index :ci_runners, :token_encrypted
    remove_concurrent_index :projects, :runners_token_encrypted
    remove_concurrent_index :namespaces, :runners_token_encrypted, unique: true
  end
end
