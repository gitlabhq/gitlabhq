# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddCompositeIndexOnMergeRequestsMergeCommitSha < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  # The default index name is too long for PostgreSQL and would thus be
  # truncated.
  INDEX_NAME = 'index_merge_requests_on_tp_id_and_merge_commit_sha_and_id'

  COLUMNS = [:target_project_id, :merge_commit_sha, :id]

  disable_ddl_transaction!

  def up
    return if index_is_present?

    add_concurrent_index(:merge_requests, COLUMNS, name: INDEX_NAME)
  end

  def down
    return unless index_is_present?

    remove_concurrent_index(:merge_requests, COLUMNS, name: INDEX_NAME)
  end

  def index_is_present?
    index_exists?(:merge_requests, COLUMNS, name: INDEX_NAME)
  end
end
