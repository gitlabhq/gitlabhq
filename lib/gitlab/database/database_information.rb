# frozen_string_literal: true

module Gitlab
  module Database
    # Collects a read-only PostgreSQL state snapshot for the
    # "Database information" panel on /admin/database_diagnostics.
    class DatabaseInformation
      DEFAULT_DATABASE_NAMES = %w[main].freeze

      SCHEMAS_SQL = <<~SQL
        SELECT n.nspname AS name,
          (n.nspname = current_schema()) AS is_current,
          pg_catalog.pg_get_userbyid(n.nspowner) AS owner
        FROM pg_catalog.pg_namespace n
        WHERE n.nspname NOT IN ('pg_catalog', 'pg_toast', 'information_schema')
        ORDER BY is_current DESC, name ASC
      SQL

      def self.execute(database_names: DEFAULT_DATABASE_NAMES)
        new(database_names: database_names).execute
      end

      def initialize(database_names: DEFAULT_DATABASE_NAMES)
        @database_names = database_names
      end

      def execute
        {
          databases: @database_names.index_with { |name| collect_for_database(name) }
        }
      end

      private

      def collect_for_database(database_name)
        model = Gitlab::Database.database_base_models[database_name]
        return { error: "Unknown database: #{database_name}" } unless model

        connection = model.connection

        {
          current_user: connection.select_value('SELECT current_user').to_s,
          search_path: connection.select_value('SHOW search_path').to_s,
          schemas: connection.select_all(SCHEMAS_SQL).map do |row|
            {
              name: row['name'],
              current: ActiveModel::Type::Boolean.new.cast(row['is_current']),
              owner: row['owner']
            }
          end
        }
      rescue StandardError => e
        Gitlab::ErrorTracking.track_exception(e, database_name: database_name)
        { error: "Failed to gather information for database: #{database_name}" }
      end
    end
  end
end
