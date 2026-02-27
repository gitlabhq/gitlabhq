# frozen_string_literal: true

module ClickHouse
  class Migration
    cattr_accessor :verbose, :client_configuration
    attr_accessor :name, :version

    def initialize(connection, name = self.class.name, version = nil)
      @connection = connection
      @name    = name
      @version = version
    end

    self.verbose = true

    MIGRATION_FILENAME_REGEXP = /\A([0-9]+)_([_a-z0-9]*)\.?([_a-z0-9]*)?\.rb\z/

    def execute(query)
      query = ReplicatedTableEnginePatcher.patch_replicated(query) if connection.replicated_engine?
      connection.execute(query)
    end

    def up
      return unless self.class.respond_to?(:up)

      self.class.up
    end

    def down
      return unless self.class.respond_to?(:down)

      self.class.down
    end

    # Execute this migration in the named direction
    def migrate(direction)
      return unless respond_to?(direction)

      case direction
      when :up   then announce 'migrating'
      when :down then announce 'reverting'
      end

      time = Benchmark.measure do
        exec_migration(direction)
      end

      case direction
      when :up   then announce format("migrated (%.4fs)", time.real)
                      write
      when :down then announce format("reverted (%.4fs)", time.real)
                      write
      end
    end

    def create_dictionary(definition, source_tables:)
      unless definition.include?('CLICKHOUSE(') # We only support ClickHouse-based dictionaries
        raise "Unsupported dictionary source (only CLICKHOUSE source is supported): #{definition}"
      end

      source_tables.each do |table|
        definition = definition.gsub(table.to_s, "#{connection.database_name}.#{table}")
      end
      create_statement = definition.gsub('CLICKHOUSE(', "CLICKHOUSE(#{dictionary_credentials}")
      execute(create_statement)
    end

    # Safely swap two tables using RENAME (gVisor-compatible alternative to EXCHANGE)
    #
    # NOTE: When running in CI (detected via CI environment variable), this uses RENAME
    # instead of EXCHANGE for gVisor compatibility. When running outside CI, it uses
    # the native EXCHANGE TABLES operation which is atomic.
    #
    # RENAME is non-atomic (may fail partway), but:
    # - Migrations run in controlled environment with no concurrent traffic
    # - Migration framework will mark as failed and allow retry
    # - Pre-flight validation reduces risk of partial failure
    # - Risk is acceptable for one-time schema migrations in CI
    #
    # @param table_a [String] First table name
    # @param table_b [String] Second table name
    # @param temp_suffix [String] Suffix for temporary table name (default: '_swap_temp')
    def safe_table_swap(table_a, table_b, temp_suffix = '_swap_temp')
      unless running_in_ci?
        # Outside CI: use native EXCHANGE TABLES (atomic operation)
        execute "EXCHANGE TABLES #{table_a} AND #{table_b}"
        return
      end

      temp_name = "#{table_a}#{temp_suffix}"

      # Pre-flight validation (only in CI mode)
      unless connection.table_exists?(table_a)
        raise ClickHouse::MigrationSupport::Errors::Base, "Table #{table_a} does not exist"
      end

      unless connection.table_exists?(table_b)
        raise ClickHouse::MigrationSupport::Errors::Base, "Table #{table_b} does not exist"
      end

      if connection.table_exists?(temp_name)
        raise ClickHouse::MigrationSupport::Errors::Base, "Temporary table #{temp_name} already exists"
      end

      # Perform the three-way swap
      # This is equivalent to EXCHANGE but works on gVisor (no renameat2 syscall)
      execute "RENAME TABLE #{table_a} TO #{temp_name}, #{table_b} TO #{table_a}, #{temp_name} TO #{table_b}"
    rescue StandardError => e
      # If swap fails, provide diagnostic information for manual recovery
      existing = fetch_table_list
      raise ClickHouse::MigrationSupport::Errors::Base,
        "Table swap failed: #{e.message}. Current tables: #{existing.inspect}"
    end

    private

    attr_reader :connection

    def exec_migration(direction)
      # noinspection RubyCaseWithoutElseBlockInspection
      case direction
      when :up then up
      when :down then down
      end
    end

    def write(text = '')
      $stdout.puts(text) if verbose
    end

    def announce(message)
      text = "#{version} #{name}: #{message}"
      length = [0, 75 - text.length].max
      write format('== %s %s', text, '=' * length)
    end

    def column_default_present?(table, column)
      q = <<~SQL
      SELECT default_expression
      FROM system.columns
      WHERE table = {table:String} AND name = {column:String} AND database = {database:String}
      SQL

      query = ClickHouse::Client::Query.new(raw_query: q, placeholders: {
        table: table,
        column: column,
        database: connection.database_name
      })

      row = connection.select(query).first
      row['default_expression'] != ''
    end

    def dictionary_credentials
      config = connection.database_config

      secure = config.instance_variable_get(:@url).start_with?('https')
      <<~TEXT
      USER '#{config.instance_variable_get(:@username)}'
      PASSWORD '#{config.instance_variable_get(:@password).to_s.gsub("'", "''")}'
      SECURE '#{secure ? '1' : '0'}'
      TEXT
    end

    def fetch_table_list
      query = <<~SQL
        SELECT name
        FROM system.tables
        WHERE database = {database:String}
        ORDER BY name
      SQL

      connection.select(
        ClickHouse::Client::Query.new(
          raw_query: query,
          placeholders: { database: connection.database_name }
        )
      ).map { |row| row['name'] } # rubocop:disable Rails/Pluck -- ClickHouse results don't support pluck
    end

    def running_in_ci?
      ENV['CI'].present?
    end
  end
end
