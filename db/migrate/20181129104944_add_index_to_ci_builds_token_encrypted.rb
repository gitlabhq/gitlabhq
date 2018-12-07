# frozen_string_literal: true

class AddIndexToCiBuildsTokenEncrypted < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_builds, :token_encrypted, unique: true, where: 'token_encrypted IS NOT NULL'
  end

  def down
    remove_concurrent_index :ci_builds, :token_encrypted
  end
end
