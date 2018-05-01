namespace :gitlab do
  namespace :db do
    desc 'GitLab | Manually insert schema migration version'
    task :mark_migration_complete, [:version] => :environment do |_, args|
      unless args[:version]
        puts "Must specify a migration version as an argument".color(:red)
        exit 1
      end

      version = args[:version].to_i
      if version == 0
        puts "Version '#{args[:version]}' must be a non-zero integer".color(:red)
        exit 1
      end

      sql = "INSERT INTO schema_migrations (version) VALUES (#{version})"
      begin
        ActiveRecord::Base.connection.execute(sql)
        puts "Successfully marked '#{version}' as complete".color(:green)
      rescue ActiveRecord::RecordNotUnique
        puts "Migration version '#{version}' is already marked complete".color(:yellow)
      end
    end

    desc 'Drop all tables'
    task drop_tables: :environment do
      connection = ActiveRecord::Base.connection

      # If MySQL, turn off foreign key checks
      connection.execute('SET FOREIGN_KEY_CHECKS=0') if Gitlab::Database.mysql?

      tables = connection.tables
      tables.delete 'schema_migrations'
      # Truncate schema_migrations to ensure migrations re-run
      connection.execute('TRUNCATE schema_migrations')

      # Drop tables with cascade to avoid dependent table errors
      # PG: http://www.postgresql.org/docs/current/static/ddl-depend.html
      # MySQL: http://dev.mysql.com/doc/refman/5.7/en/drop-table.html
      # Add `IF EXISTS` because cascade could have already deleted a table.
      tables.each { |t| connection.execute("DROP TABLE IF EXISTS #{connection.quote_table_name(t)} CASCADE") }

      # If MySQL, re-enable foreign key checks
      connection.execute('SET FOREIGN_KEY_CHECKS=1') if Gitlab::Database.mysql?
    end

    desc 'Configures the database by running migrate, or by loading the schema and seeding if needed'
    task configure: :environment do
      if ActiveRecord::Base.connection.tables.any?
        Rake::Task['db:migrate'].invoke
      else
        Rake::Task['db:schema:load'].invoke
        Rake::Task['db:seed_fu'].invoke
      end
    end

    desc 'Checks if migrations require downtime or not'
    task :downtime_check, [:ref] => :environment do |_, args|
      abort 'You must specify a Git reference to compare with' unless args[:ref]

      require 'shellwords'

      ref = Shellwords.escape(args[:ref])

      migrations = `git diff #{ref}.. --diff-filter=A --name-only -- db/migrate`.lines
        .map { |file| Rails.root.join(file.strip).to_s }
        .select { |file| File.file?(file) }
        .select { |file| /\A[0-9]+.*\.rb\z/ =~ File.basename(file) }

      Gitlab::DowntimeCheck.new.check_and_print(migrations)
    end

    desc 'Output pseudonymity dump of selected table'
    task :pseudonymity_dump => :environment do
      # issue* tables
      # label* tables
      # licenses
      # merge_request* tables
      # milestones
      # namespace_statistics
      # namespaces
      # notes
      # notification_settings
      # project* tables
      # subscriptions
      # users

      # REMOVE PRODUCTION INFRA SCRIPT AS PART OF MR> 
      puts Pseudonymity::Table.table_to_csv("approvals",
        ["id","merge_request_id","user_id","created_at","updated_at"],
        ["id", "merge_request_id", "user_id"])
      puts Pseudonymity::Table.table_to_csv("approver_groups",
        ["id","target_type","group_id","created_at","updated_at"],
        ["id","group_id"])
      puts Pseudonymity::Table.table_to_csv("board_assignees",
        ["id","board_id","assignee_id"],
        ["id","board_id","assignee_id"])
      puts Pseudonymity::Table.table_to_csv("board_labels",
        ["id","board_id","label_id"],
        ["id","board_id","label_id"])
      puts Pseudonymity::Table.table_to_csv("boards",
        ["id","project_id","created_at","updated_at","milestone_id","group_id","weight"],
        ["id","project_id","milestone_id","group_id"])
      puts Pseudonymity::Table.table_to_csv("epic_issues",
        ["id","epic_id","issue_id","relative_position"],
        ["id","epic_id","issue_id"])
      puts Pseudonymity::Table.table_to_csv("epic_metrics",
        ["id","epic_id","created_at","updated_at"],
        ["id"])
      puts Pseudonymity::Table.table_to_csv("epics",
        ["id", "milestone_id", "group_id", "author_id", "assignee_id", "iid", "cached_markdown_version", "updated_by_id", "last_edited_by_id", "lock_version", "start_date", "end_date", "last_edited_at", "created_at", "updated_at", "title", "description"],
        ["id", "milestone_id", "group_id", "author_id", "assignee_id", "iid", "cached_markdown_version", "updated_by_id", "last_edited_by_id", "lock_version", "start_date", "end_date", "last_edited_at", "created_at", "updated_at"])
      puts Pseudonymity::Table.table_to_csv("issue_assignees",
        ["user_id","issue_id"],
        ["user_id","issue_id"])
      puts Pseudonymity::Table.table_to_csv("issue_links",
        ["id", "source_id", "target_id", "created_at", "updated_at"],
        ["id", "source_id", "target_id"])
      puts Pseudonymity::Table.table_to_csv("issue_metrics",
        [],
        [])
      puts Pseudonymity::Table.table_to_csv("issues",
        [],
        [])
    end
  end
end
