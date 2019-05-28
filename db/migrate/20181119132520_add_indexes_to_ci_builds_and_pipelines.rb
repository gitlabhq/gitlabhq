# frozen_string_literal: true

class AddIndexesToCiBuildsAndPipelines < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    indexes.each do |index|
      add_concurrent_index(*index)
    end
  end

  def down
    indexes.each do |index|
      remove_concurrent_index(*index)
    end
  end

  private

  def indexes
    [
      [
        :ci_pipelines,
        [:project_id, :ref, :id],
        {
          order: { id: :desc },
          name: 'index_ci_pipelines_on_project_idandrefandiddesc'
        }
      ],
      [
        :ci_builds,
        [:commit_id, :artifacts_expire_at, :id],
        {
          where: "type::text = 'Ci::Build'::text AND (retried = false OR retried IS NULL) AND (name::text = ANY (ARRAY['sast'::character varying, 'dependency_scanning'::character varying, 'sast:container'::character varying, 'container_scanning'::character varying, 'dast'::character varying]::text[]))",
          name: 'index_ci_builds_on_commit_id_and_artifacts_expireatandidpartial'
        }
      ]
    ]
  end
end
