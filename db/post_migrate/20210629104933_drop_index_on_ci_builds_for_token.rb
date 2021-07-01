# frozen_string_literal: true

class DropIndexOnCiBuildsForToken < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEXNAME = :index_ci_builds_on_token

  def up
    remove_concurrent_index_by_name :ci_builds, INDEXNAME
  end

  def down
    add_concurrent_index :ci_builds, :token, unique: true, name: INDEXNAME
  end
end
