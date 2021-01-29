# frozen_string_literal: true

class AddOldestMergeRequestsIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::SchemaHelpers
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  INDEX = 'index_on_merge_requests_for_latest_diffs'

  def up
    return if index_exists_by_name?('merge_requests', INDEX)

    execute "CREATE INDEX CONCURRENTLY #{INDEX} ON merge_requests " \
      'USING btree (target_project_id) INCLUDE (id, latest_merge_request_diff_id)'

    create_comment(
      'INDEX',
      INDEX,
      'Index used to efficiently obtain the oldest merge request for a commit SHA'
    )
  end

  def down
    return unless index_exists_by_name?('merge_requests', INDEX)

    execute "DROP INDEX CONCURRENTLY #{INDEX}"
  end
end
