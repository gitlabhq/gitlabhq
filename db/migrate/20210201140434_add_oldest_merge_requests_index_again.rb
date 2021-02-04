# frozen_string_literal: true

class AddOldestMergeRequestsIndexAgain < ActiveRecord::Migration[6.0]
  include Gitlab::Database::SchemaHelpers
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  INDEX = 'index_on_merge_requests_for_latest_diffs'

  def up
    execute "DROP INDEX CONCURRENTLY #{INDEX}" if invalid_index?

    return if index_exists_by_name?('merge_requests', INDEX)

    begin
      disable_statement_timeout do
        execute "CREATE INDEX CONCURRENTLY #{INDEX} ON merge_requests " \
          'USING btree (target_project_id) INCLUDE (id, latest_merge_request_diff_id)'
      end
    rescue ActiveRecord::StatementInvalid => ex
      # Due to https://github.com/lfittl/pg_query/issues/184, if the CREATE
      # INDEX statement fails, we trigger a separate error due to the Gem not
      # supporting the INCLUDE syntax.
      #
      # To work around this, we raise a custom error instead, as these won't
      # have a query context injected.
      raise "The index #{INDEX} couldn't be added: #{ex.message}"
    end

    create_comment(
      'INDEX',
      INDEX,
      'Index used to efficiently obtain the oldest merge request for a commit SHA'
    )
  end

  def down
    return unless index_exists_by_name?('merge_requests', INDEX)

    disable_statement_timeout do
      execute "DROP INDEX CONCURRENTLY #{INDEX}"
    end
  end

  def invalid_index?
    result = execute(<<~SQL)
      SELECT pg_class.relname
      FROM pg_class, pg_index
      WHERE pg_index.indisvalid = false
      AND pg_index.indexrelid = pg_class.oid
      AND pg_class.relname = '#{INDEX}';
    SQL

    result.values.any?
  end
end
