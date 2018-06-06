class AddIndexToCiBuildsArtifactsFile < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # We add an temporary index to `ci_builds.artifacts_file` column to avoid statements timeout in legacy artifacts migrations
    # This index is to be removed after we have cleaned up background migrations
    # https://gitlab.com/gitlab-org/gitlab-ce/issues/46866
    if Gitlab::Database.postgresql?
      add_concurrent_index :ci_builds, :artifacts_file, where: "artifacts_file <> ''"
    elsif Gitlab::Database.mysql?
      add_concurrent_index :ci_builds, :artifacts_file, where: "artifacts_file <> ''", length: 20
    end
  end

  def down
    if Gitlab::Database.postgresql?
      remove_concurrent_index :ci_builds, :artifacts_file, where: "artifacts_file <> ''"
    elsif Gitlab::Database.mysql?
      remove_concurrent_index :ci_builds, :artifacts_file, where: "artifacts_file <> ''", length: 20
    end
  end
end
