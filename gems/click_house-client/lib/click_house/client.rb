# frozen_string_literal: true

require 'addressable'
require 'json'
require 'active_support/time'
require 'active_support/notifications'
require_relative "client/database"
require_relative "client/configuration"
require_relative "client/bind_index_manager"
require_relative "client/query_like"
require_relative "client/query"
require_relative "client/formatter"
require_relative "client/response"

module ClickHouse
  module Client
    class << self
      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
        configuration.validate!
      end
    end

    Error = Class.new(StandardError)
    ConfigurationError = Class.new(Error)
    DatabaseError = Class.new(Error)
    QueryError = Class.new(Error)

    # Executes a SELECT database query
    def self.select(query, database, configuration = self.configuration)
      instrumented_execute(query, database, configuration) do |response, instrument|
        parsed_response = configuration.json_parser.parse(response.body)

        instrument[:statistics] = parsed_response['statistics']&.symbolize_keys

        Formatter.format(parsed_response)
      end
    end

    # Executes any kinds of database query without returning any data (INSERT, DELETE)
    def self.execute(query, database, configuration = self.configuration)
      instrumented_execute(query, database, configuration) do |response, instrument|
        if response.headers['x-clickhouse-summary']
          instrument[:statistics] =
            Gitlab::Json.parse(response.headers['x-clickhouse-summary']).symbolize_keys
        end
      end

      true
    end

    private_class_method def self.lookup_database(configuration, database)
      configuration.databases[database].tap do |db|
        raise ConfigurationError, "The database '#{database}' is not configured" unless db
      end
    end

    private_class_method def self.instrumented_execute(query, database, configuration)
      db = lookup_database(configuration, database)

      query = ClickHouse::Client::Query.new(raw_query: query) unless query.is_a?(ClickHouse::Client::QueryLike)
      ActiveSupport::Notifications.instrument('sql.click_house', { query: query, database: database }) do |instrument|
        # Use a multipart POST request where the placeholders are sent with the param_ prefix
        # See: https://github.com/ClickHouse/ClickHouse/issues/8842
        query_with_params = query.placeholders.transform_keys { |key| "param_#{key}" }
        query_with_params['query'] = query.to_sql

        response = configuration.http_post_proc.call(
          db.uri.to_s,
          db.headers,
          query_with_params
        )

        raise DatabaseError, response.body unless response.success?

        yield response, instrument
      end
    end
  end
end
