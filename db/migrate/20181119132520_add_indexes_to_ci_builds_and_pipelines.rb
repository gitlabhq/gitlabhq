# frozen_string_literal: true

class AddIndexesToCiBuildsAndPipelines < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_pipelines, [:project_id, :ref, :id], order: { id: :desc }
    add_concurrent_index :ci_builds, [:commit_id, :artifacts_expire_at, :id], where: "type = 'Ci::Build' AND (retried = false OR retried IS NULL) AND name IN ('sast', 'dependency_scanning', 'sast:container', 'container_scanning', 'dast')"
  end

  def down
    remove_concurrent_index :ci_pipelines, [:project_id, :ref, :id], order: { id: :desc }
    remove_concurrent_index :ci_builds, [:commit_id, :artifacts_expire_at, :id], where: "type = 'Ci::Build' AND (retried = false OR retried IS NULL) AND name IN ('sast', 'dependency_scanning', 'sast:container', 'container_scanning', 'dast')"
  end
end
