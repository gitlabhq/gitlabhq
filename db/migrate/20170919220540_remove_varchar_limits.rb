# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveVarcharLimits < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # Because ALTER TABLE locks the table, even briefly, and we're doing
  # this on many tables in an arbitrary order there would be a severe
  # risk of a deadlock if we did it all in a single transaction. The
  # only way to avoid it would be to ensure we did it in the same
  # order that every other transaction accesses these tables which
  # would be impossible.
  disable_ddl_transaction!

  # We're removing varchar(510) and varchar(255) limits which are a
  # relic of the MySQL->Postgres migration in the past...
  # c.f. https://github.com/gitlabhq/mysql-postgresql-converter/issues/8

  # Note that doing ALTER COLUMN to go from varchar(xxx) to plain
  # varchar does not need to rewrite the table or even do a full table
  # scan to verify the constraint. It does require obtaining a lock on
  # the table so on very busy databases it could cause a short
  # outage. Doing this in separate transactions should minimize this.

  def up
    return unless Gitlab::Database.postgresql?

    connection.tables.each do |table|
      next unless gitlab_table?(table)

      varchars = columns(table).select { |col| old_mysql_varchar?(col) }
      next if varchars.empty?

      # Do a single change_table to alter column on all the columns in
      # a table together to minimize the number of lock acquisitions
      say "Removing #{varchars.length} leftover varchar limits from MySQL migration from table #{table}"
      change_table table do |t|
        varchars.each do |c|
          t.change c.name, :string
        end
      end
    end
  end

  # No down method since these limits ought never have been present

  def gitlab_table?(table)
    return table != 'schema_migrations'
  end

  def old_mysql_varchar?(col)
    return (col.cast_type.is_a?(ActiveRecord::Type::String) &&
            (col.cast_type.limit == 510 || col.cast_type.limit == 255))
  end
end
