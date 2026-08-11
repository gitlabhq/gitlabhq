# frozen_string_literal: true

require_relative 'setup_task'

namespace :gitlab do
  namespace :siphon do
    # Prepares every configured database for Siphon replication. Per database it installs the
    # siphon_alter_publication SECURITY DEFINER function, grants EXECUTE on it to the siphon user
    # only, creates an empty publication, and grants USAGE and SELECT on the public and
    # gitlab_partitions_* schemas to the Siphon users. Safe to run repeatedly.
    #
    # The Siphon users must already exist. Creating them needs a superuser, because the REPLICATION
    # attribute on siphon_replicator is superuser-only, so this task only reports them as missing.
    #
    #   bundle exec rake gitlab:siphon:setup
    #   SIPHON_DATABASE=ci bundle exec rake gitlab:siphon:setup
    #
    # SIPHON_USER_PREFIX       role name prefix, default `siphon`
    # SIPHON_DATABASE          limit to one database (`main`, `ci`, `sec`), default all
    # SIPHON_PUBLICATION_NAME  publication name, default `siphon_publication_<database>_1`,
    #                          only allowed together with SIPHON_DATABASE
    desc 'GitLab | Siphon | Set up the publication, helper function and grants on every configured database'
    task setup: :gitlab_environment do
      Tasks::Gitlab::Siphon::SetupTask.new(
        user_prefix: ENV['SIPHON_USER_PREFIX'],
        database: ENV['SIPHON_DATABASE'],
        publication_name: ENV['SIPHON_PUBLICATION_NAME']
      ).execute
    end

    # Truncates every ClickHouse table listed in db/siphon/tables/*.yml, so an initial snapshot can
    # be replayed from scratch. Destructive, and refuses to run without the confirmation variable.
    #
    #   FORCE_CLEAN_SIPHON_TABLES_IN_CLICKHOUSE=true bundle exec rake gitlab:siphon:clean_clickhouse
    #   FORCE_CLEAN_SIPHON_TABLES_IN_CLICKHOUSE=true SIPHON_TABLES=work_items,siphon_events \
    #     bundle exec rake gitlab:siphon:clean_clickhouse
    #
    # FORCE_CLEAN_SIPHON_TABLES_IN_CLICKHOUSE  must be `true`, no default
    # SIPHON_TABLES                            comma separated ClickHouse table names, default all
    desc 'GitLab | Siphon | Truncate every Siphon table in the ClickHouse main database'
    task clean_clickhouse: :gitlab_environment do
      unless ENV['FORCE_CLEAN_SIPHON_TABLES_IN_CLICKHOUSE'] == 'true'
        abort 'Refusing to truncate the Siphon ClickHouse tables. This deletes all replicated data. ' \
          'Re-run with FORCE_CLEAN_SIPHON_TABLES_IN_CLICKHOUSE=true to confirm.'
      end

      abort 'The main ClickHouse database is not configured.' unless
        ClickHouse::Client.database_configured?(:main)

      # `dedup_by_table` means `target` is a `Null` engine pass-through holding no data, and it
      # rejects TRUNCATE anyway. Same precedence as the have_correct_replication_target matcher.
      tables = Dir[Rails.root.join('db/siphon/tables/*.yml')].flat_map do |file|
        YAML.safe_load_file(file)
          .fetch('replication_targets', [])
          .select { |target| target['name'] == 'clickhouse_main' }
          .flat_map do |target|
            [
              target['dedup_by_table'] || target['target'],
              target['dedup_by_columns_lookup_table'],
              # MV targets keep their rows when the source is truncated, so they need clearing too
              *target['downstream_materialized_views']
            ]
          end
      end.compact.uniq.sort

      requested = ENV['SIPHON_TABLES'].to_s.split(',').map(&:strip).reject(&:empty?)
      if requested.any?
        unknown = requested - tables
        abort "Not Siphon ClickHouse tables: #{unknown.join(', ')}" if unknown.any?

        tables &= requested
      end

      tables.each do |table|
        puts "TRUNCATE TABLE #{table}"

        query = ClickHouse::Client::Query.new(
          raw_query: 'TRUNCATE TABLE IF EXISTS {table: Identifier}',
          placeholders: { table: table }
        )

        ClickHouse::Client.execute(query, :main)
      end

      puts "Truncated #{tables.size} tables."
    end
  end
end
