# frozen_string_literal: true

class NewCiIndexes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME_1 = 'index_ci_pipelines_on_project_id_and_ref_and_id_desc'.freeze
  INDEX_NAME_2 = 'partial_index_ci_builds_on_commit_id_and_artifacts_id_and_id'.freeze

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_pipelines, [:project_id, :ref, :id],
      name: INDEX_NAME_1,
      order: {project_id: :asc, ref: :asc, id: :desc}

    add_concurrent_index :ci_builds, [:commit_id, :name, :artifacts_expire_at, :id],
      name: INDEX_NAME_2,
      where: <<-SQL_WHERE
        type = 'Ci::Build'
        and (retried = false or retried is null)
        and name in ('sast', 'dependency_scanning', 'sast:container', 'container_scanning', 'dast')
SQL_WHERE
  end

  def down
    remove_concurrent_index_by_name(:ci_pipelines, INDEX_NAME_1)
    remove_concurrent_index_by_name(:ci_builds, INDEX_NAME_2)
  end
end
