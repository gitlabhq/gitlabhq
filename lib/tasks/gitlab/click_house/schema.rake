# frozen_string_literal: true

click_house_database_names = %i[main]

namespace :gitlab do
  namespace :clickhouse do
    click_house_database_names.each do |database|
      namespace :schema do
        namespace :dump do
          desc "GitLab | ClickHouse | Dump the #{database} ClickHouse database schema"
          task database, [:skip_unless_configured] => :environment do |_t, args|
            if args[:skip_unless_configured] && !::ClickHouse::Client.database_configured?(database)
              puts "The '#{database}' ClickHouse database is not configured, skipping load"
              next
            end

            dump(database)
          end
        end

        namespace :load do
          desc "GitLab | ClickHouse | Load the #{database} database from schema dump"
          task database, [:skip_unless_configured] => :environment do |_t, args|
            if args[:skip_unless_configured] && !::ClickHouse::Client.database_configured?(database)
              puts "The '#{database}' ClickHouse database is not configured, skipping load"
              next
            end

            load_schema(database)
          end
        end
      end
    end

    namespace :schema do
      desc 'GitLab | ClickHouse | Load the databases from schema dump'
      task :load, [:skip_unless_configured] => :environment do |_t, args|
        click_house_database_names.each do |database|
          puts "Running gitlab:clickhouse:schema:load:#{database} rake task"
          Rake::Task["gitlab:clickhouse:schema:load:#{database}"].invoke(args[:skip_unless_configured])
        end
      end

      desc 'GitLab | ClickHouse | Dump the databases schema'
      task :dump, [:skip_unless_configured] => :environment do |_t, args|
        click_house_database_names.each do |database|
          puts "Running gitlab:clickhouse:schema:dump:#{database} rake task"
          Rake::Task["gitlab:clickhouse:schema:dump:#{database}"].invoke(args[:skip_unless_configured])
        end
      end
    end

    private

    def load_schema(database)
      schema_dump_path = Rails.root.join("db/click_house/#{database}.sql")

      raise "ClickHouse schema dump not found at #{schema_dump_path}" unless File.exist?(schema_dump_path)

      schema_sql = File.read(schema_dump_path)

      ClickHouse::Client.configuration.databases.each_key do |db|
        connection = ::ClickHouse::Connection.new(db)

        # CH doesn't support multiple statements by default
        schema_sql.split(';').each do |statement|
          next if statement.strip.empty?

          connection.execute(statement)
        end

        # Load migrations from schema files
        ClickHouse::SchemaMigrations.load_all(connection, database)
      end
    end

    def dump(database)
      return if Rails.env.test?

      connection = ClickHouse::Connection.new(database)
      database_name = connection.database_name

      tables_query = <<~SQL
        SELECT
        	groupConcat(';\n\n')(formatted_statement) AS all_statements
        FROM
          (
            SELECT
              replaceRegexpAll (formatQuery (create_table_query), {database_pattern:String}, '') AS formatted_statement            FROM
              system.tables
            WHERE
              database = {database:String}
            ORDER BY
              CASE
                WHEN engine LIKE '%View%' THEN 1
                ELSE 0
              END,
              name
          );
      SQL

      query = ClickHouse::Client::Query.new(
        raw_query: tables_query,
        placeholders: {
          database: database_name,
          database_pattern: "#{database_name}\\."
        }
      )

      result = connection.select(query).dig(0, 'all_statements')

      File.write(Rails.root.join('db', 'click_house', "#{database}.sql"), result)
    end
  end
end
