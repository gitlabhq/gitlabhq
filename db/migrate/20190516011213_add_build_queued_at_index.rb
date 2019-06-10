# frozen_string_literal: true

# This migration make queued_at field indexed to speed up builds filtering by job_age

class AddBuildQueuedAtIndex < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_builds, :queued_at
  end

  def down
    remove_concurrent_index :ci_builds, :queued_at
  end
end
