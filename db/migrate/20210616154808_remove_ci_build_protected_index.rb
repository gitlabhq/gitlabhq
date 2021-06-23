# frozen_string_literal: true

class RemoveCiBuildProtectedIndex < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  INDEX_NAME = 'index_ci_builds_on_protected'

  disable_ddl_transaction!

  def up
    remove_concurrent_index :ci_builds, :protected, name: INDEX_NAME
  end

  def down
    add_concurrent_index :ci_builds, :protected, name: INDEX_NAME
  end
end
