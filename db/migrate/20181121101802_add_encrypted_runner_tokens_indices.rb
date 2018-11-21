# frozen_string_literal: true

class AddEncryptedRunnerTokensIndices < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :namespaces, :runners_token_encrypted, unique: true
    add_concurrent_index :projects, :runners_token_encrypted, unique: true
    add_concurrent_index :ci_runners, :token_encrypted, unique: true
  end

  def down
    remove_concurrent_index :ci_runners, :token_encrypted
    remove_concurrent_index :projects, :runners_token_encrypted
    remove_concurrent_index :namespaces, :runners_token_encrypted
  end
end
