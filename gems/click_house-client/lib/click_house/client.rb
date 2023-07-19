# frozen_string_literal: true

require 'addressable'
require 'json'
require 'active_support/time'
require_relative "client/database"
require_relative "client/configuration"
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

    # Executes a SELECT database query
    def self.select(query, database, configuration = self.configuration)
      db = lookup_database(configuration, database)

      response = configuration.http_post_proc.call(
        db.uri.to_s,
        db.headers,
        "#{query} FORMAT JSON" # always return JSON
      )

      raise DatabaseError, response.body unless response.success?

      Formatter.format(configuration.json_parser.parse(response.body))
    end

    # Executes any kinds of database query without returning any data (INSERT, DELETE)
    def self.execute(query, database, configuration = self.configuration)
      db = lookup_database(configuration, database)

      response = configuration.http_post_proc.call(
        db.uri.to_s,
        db.headers,
        query
      )

      raise DatabaseError, response.body unless response.success?

      true
    end

    private_class_method def self.lookup_database(configuration, database)
      configuration.databases[database].tap do |db|
        raise ConfigurationError, "The database '#{database}' is not configured" unless db
      end
    end
  end
end
