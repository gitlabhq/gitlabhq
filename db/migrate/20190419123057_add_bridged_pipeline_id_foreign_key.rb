# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddBridgedPipelineIdForeignKey < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_builds, :upstream_pipeline_id, where: 'upstream_pipeline_id IS NOT NULL'
    add_concurrent_foreign_key :ci_builds, :ci_pipelines, column: :upstream_pipeline_id
  end

  def down
    remove_foreign_key :ci_builds, column: :upstream_pipeline_id
    remove_concurrent_index :ci_builds, :upstream_pipeline_id
  end
end
