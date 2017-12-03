class RenameCommitStatusToCiJobType < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    migrate_column_value(:deployments, :deployable_type, 'CommitStatus', 'Ci::Job')
    migrate_column_value(:taggings, :taggable_type, 'CommitStatus', 'Ci::Job')
    migrate_column_value(:ci_builds, :type, 'CommitStatus', 'Ci::Job')
  end

  def down
    migrate_column_value(:deployments, :deployable_type, 'Ci::Job', 'CommitStatus')
    migrate_column_value(:taggings, :taggable_type, 'Ci::Job', 'CommitStatus')
    migrate_column_value(:ci_builds, :type, 'Ci::Job', 'CommitStatus')
  end

  private

  def migrate_column_value(table, column, from, to)
    from = from.demodulize.underscore
    to = to.demodulize.underscore

    create_partial_index(table, column, from)

    begin
      update_column_in_batches(table, column, to) do |table, query|
        query.where(table[column].eq(from))
      end
    ensure
      drop_partial_index(table, column, from)
    end
  end

  def index_name(table, column, value)
    "index_on_#{table}_#{column}_when_#{value}"
  end

  def create_partial_index(table, column, value)
    name = index_name(table, column, value)
    return if index_exists?(table, column, name: name)

    execute("CREATE INDEX CONCURRENTLY #{name} ON #{table} (#{column}) WHERE #{column}='#{value}'")
  end

  def drop_partial_index(table, column, value)
    execute("DROP INDEX CONCURRENTLY #{index_name(table, column, value)}")
  end
end
