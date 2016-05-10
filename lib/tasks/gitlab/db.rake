namespace :gitlab do
  namespace :db do
    desc 'GitLab | Manually insert schema migration version'
    task :mark_migration_complete, [:version] => :environment do |_, args|
      unless args[:version]
        puts "Must specify a migration version as an argument".red
        exit 1
      end

      version = args[:version].to_i
      if version == 0
        puts "Version '#{args[:version]}' must be a non-zero integer".red
        exit 1
      end

      sql = "INSERT INTO schema_migrations (version) VALUES (#{version})"
      begin
        ActiveRecord::Base.connection.execute(sql)
        puts "Successfully marked '#{version}' as complete".green
      rescue ActiveRecord::RecordNotUnique
        puts "Migration version '#{version}' is already marked complete".yellow
      end
    end

    desc 'Drop all tables'
    task :drop_tables => :environment do
      connection = ActiveRecord::Base.connection
      tables = connection.tables
      tables.delete 'schema_migrations'
      # Truncate schema_migrations to ensure migrations re-run
      connection.execute('TRUNCATE schema_migrations')

      # Drop tables with cascade to avoid dependent table errors
      # PG: http://www.postgresql.org/docs/current/static/ddl-depend.html
      # MySQL: http://dev.mysql.com/doc/refman/5.7/en/drop-table.html
      # Add `IF EXISTS` because cascade could have already deleted a table.
      tables.each { |t| connection.execute("DROP TABLE IF EXISTS #{t} CASCADE") }
    end
  end
end
