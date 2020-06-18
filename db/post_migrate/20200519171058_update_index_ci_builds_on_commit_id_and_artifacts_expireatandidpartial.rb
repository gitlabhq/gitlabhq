# frozen_string_literal: true

class UpdateIndexCiBuildsOnCommitIdAndArtifactsExpireatandidpartial < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  OLD_INDEX_NAME = 'index_ci_builds_on_commit_id_and_artifacts_expireatandidpartial'
  NEW_INDEX_NAME = 'index_ci_builds_on_commit_id_artifacts_expired_at_and_id'

  OLD_CLAUSE = "type::text = 'Ci::Build'::text AND (retried = false OR retried IS NULL) AND
               (name::text = ANY (ARRAY['sast'::character varying,
               'dependency_scanning'::character varying,
               'sast:container'::character varying,
               'container_scanning'::character varying,
               'dast'::character varying]::text[]))"

  NEW_CLAUSE = "type::text = 'Ci::Build'::text AND (retried = false OR retried IS NULL) AND
               (name::text = ANY (ARRAY['sast'::character varying,
               'secret_detection'::character varying,
               'dependency_scanning'::character varying,
               'container_scanning'::character varying,
               'dast'::character varying]::text[]))"

  def up
    add_concurrent_index :ci_builds, [:commit_id, :artifacts_expire_at, :id], name: NEW_INDEX_NAME, where: NEW_CLAUSE
    remove_concurrent_index_by_name :ci_builds, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :ci_builds, [:commit_id, :artifacts_expire_at, :id], name: OLD_INDEX_NAME, where: OLD_CLAUSE
    remove_concurrent_index_by_name :ci_builds, NEW_INDEX_NAME
  end
end
