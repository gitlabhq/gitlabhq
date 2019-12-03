# This migration adds a primary key constraint to tables
# that only have a composite unique key.
#
# This is not strictly relevant to Rails (v4 does not
# support composite primary keys). However this becomes
# useful for e.g. PostgreSQL's logical replication (pglogical)
# which requires all tables to have a primary key constraint.
#
# In that sense, the migration is optional and not strictly needed.
class CompositePrimaryKeysMigration < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  Index = Struct.new(:table, :name, :columns)

  TABLES = [
    Index.new(:issue_assignees, 'index_issue_assignees_on_issue_id_and_user_id', %i(issue_id user_id)),
    Index.new(:user_interacted_projects, 'index_user_interacted_projects_on_project_id_and_user_id', %i(project_id user_id)),
    Index.new(:merge_request_diff_files, 'index_merge_request_diff_files_on_mr_diff_id_and_order', %i(merge_request_diff_id relative_order)),
    Index.new(:merge_request_diff_commits, 'index_merge_request_diff_commits_on_mr_diff_id_and_order', %i(merge_request_diff_id relative_order)),
    Index.new(:project_authorizations, 'index_project_authorizations_on_user_id_project_id_access_level', %i(user_id project_id access_level)),
    Index.new(:push_event_payloads, 'index_push_event_payloads_on_event_id', %i(event_id)),
    Index.new(:schema_migrations, 'unique_schema_migrations', %(version))
  ].freeze

  disable_ddl_transaction!

  def up
    disable_statement_timeout do
      TABLES.each do |index|
        add_primary_key(index)
      end
    end
  end

  def down
    disable_statement_timeout do
      TABLES.each do |index|
        remove_primary_key(index)
      end
    end
  end

  private

  def add_primary_key(index)
    execute "ALTER TABLE #{index.table} ADD PRIMARY KEY USING INDEX #{index.name}"
  end

  def remove_primary_key(index)
    temp_index_name = "#{index.name[0..58]}_old"
    rename_index index.table, index.name, temp_index_name if index_exists_by_name?(index.table, index.name)

    # re-create unique key index
    add_concurrent_index index.table, index.columns, unique: true, name: index.name

    # This also drops the `temp_index_name` as this is owned by the constraint
    execute "ALTER TABLE #{index.table} DROP CONSTRAINT IF EXISTS #{temp_index_name}"
  end
end
