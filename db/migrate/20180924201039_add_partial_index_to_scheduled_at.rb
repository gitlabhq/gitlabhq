# frozen_string_literal: true

class AddPartialIndexToScheduledAt < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'partial_index_ci_builds_on_scheduled_at_with_scheduled_jobs'.freeze

  disable_ddl_transaction!

  def up
    add_concurrent_index(:ci_builds, :scheduled_at, where: "scheduled_at IS NOT NULL AND type = 'Ci::Build' AND status = 'scheduled'", name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:ci_builds, INDEX_NAME)
  end
end
