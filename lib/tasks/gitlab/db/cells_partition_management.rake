# frozen_string_literal: true

namespace :gitlab do
  namespace :db do
    # @return [String]
    #   JSON array of { database, tables: [{ table_name, partition_type, partitions: [{ partition_name, from, to }] }] }
    #   Integer partition bounds are integers; time bounds are ISO 8601 strings.
    desc 'GitLab | Cells | DB | Export integer range and time partition definitions from all databases as JSON'
    task export_partition_definitions: :environment do
      all_databases = []

      Gitlab::Database::EachDatabase.each_connection(include_shared: false) do |connection, connection_name|
        next if Gitlab::Database::Partitioning::PARTITION_EXCLUDED_DATABASES.include?(connection_name)

        exporter = Gitlab::Database::Partitioning::PartitionExporter.new(connection: connection)
        tables = exporter.export

        all_databases << { database: connection_name, tables: tables }
      end

      puts Gitlab::Json.dump(all_databases)
    end

    # @param file [String] JSON file path from export_partition_definitions
    # @return [String]
    #   Summary lines per database and a total created/skipped line.
    #   Exits non-zero if any invalid entries are encountered.
    #   Set DRY_RUN=true to preview without creating partitions.
    desc 'GitLab | Cells | DB | Ensure integer range & time partitions exist on all DBs from exported definitions file'
    task :ensure_partitions, [:file] => :environment do |_, args|
      file_path = args[:file]
      unless file_path
        raise ArgumentError,
          'File path is required. Usage: rake "gitlab:db:ensure_partitions[/path/to/file.json]"'
      end

      raise ArgumentError, "File not found: #{file_path}" unless File.exist?(file_path)

      begin
        all_databases = Gitlab::Json.safe_parse(File.read(file_path))
      rescue JSON::ParserError => e
        raise ArgumentError, "Invalid JSON in #{file_path}: #{e.message}"
      end

      raise ArgumentError, 'Expected top-level JSON array of database definitions' unless all_databases.is_a?(Array)

      dry_run = Gitlab::Utils.to_boolean(ENV['DRY_RUN'], default: false)
      puts 'DRY RUN: No partitions will be created.' if dry_run

      total_created = 0
      total_skipped = 0
      created_label = dry_run ? 'would_create' : 'created'

      Gitlab::Database::EachDatabase.each_connection(include_shared: false) do |connection, connection_name|
        next if Gitlab::Database::Partitioning::PARTITION_EXCLUDED_DATABASES.include?(connection_name)

        db_entry = all_databases.find { |entry| entry['database'] == connection_name }
        next unless db_entry

        tables = db_entry['tables']
        importer = Gitlab::Database::Partitioning::PartitionImporter.new(connection: connection)
        result = importer.import(tables, dry_run: dry_run)

        total_created += result[:created]
        total_skipped += result[:skipped]

        puts "#{connection_name}: #{created_label}=#{result[:created]}, skipped=#{result[:skipped]}, " \
          "tables_processed=#{result[:tables_processed]}"
      end

      puts "Total: #{created_label}=#{total_created}, skipped=#{total_skipped}"
    end
  end
end
