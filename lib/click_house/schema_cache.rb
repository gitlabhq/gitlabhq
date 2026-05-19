# frozen_string_literal: true

module ClickHouse
  module SchemaCache
    SCHEMA_CACHE_DIR = 'db/click_house/schema_cache/%{database}'

    class << self
      def [](database)
        cache[database.to_sym] ||= Loader.new(database: database).load
      end

      def reset!
        @cache = nil
      end

      def dump(connection, database)
        result = Dumper.new(connection: connection, database: database).dump
        cache.delete(database.to_sym)
        result
      end

      def schema_cache_path(database)
        Rails.root.join(format(SCHEMA_CACHE_DIR, database: database))
      end

      def table_cache_path(database, table_name)
        schema_cache_path(database).join("#{table_name}.yml")
      end

      private

      def cache
        @cache ||= {}
      end
    end
  end
end
