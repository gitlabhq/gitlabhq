# frozen_string_literal: true

desc 'db | migration_fix_15_11'
task migration_fix_15_11: [:environment] do
  next if Gitlab.com?

  only_on = %i[main ci].select { |db| Gitlab::Database.has_database?(db) }
  Gitlab::Database::EachDatabase.each_connection(only: only_on) do |conn, database|
    begin
      first_migration = conn.execute('SELECT * FROM schema_migrations ORDER BY version ASC LIMIT 1')
    rescue ActiveRecord::StatementInvalid
      # Uninitialized DB, skip
      next
    end
    next if first_migration.none? # No migrations have been run yet
    # If we are affected, the first migration in the schema_migrations table
    # will be 20220314184009
    next unless first_migration.first['version'] == '20220314184009'

    puts "Running 15.11 migration fix for #{database}"
    fixes = File.readlines(Rails.root.join('db/15_11_migration_fixes.txt')).map(&:chomp)
    conn.transaction do
      fixes.each do |version|
        conn.execute("INSERT INTO schema_migrations (version) VALUES ('#{version}')")
      end
    end
  end
end

Rake::Task['db:migrate'].enhance(['migration_fix_15_11'])
