# frozen_string_literal: true

class RemoveRedundantStatusIndexOnCiBuilds < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index :ci_builds, :status
  end

  def down
    add_concurrent_index :ci_builds, :status
  end
end
