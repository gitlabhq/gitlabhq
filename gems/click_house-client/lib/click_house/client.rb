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

    def self.execute(query, database, configuration = self.configuration)
      db = configuration.databases[database]
      raise ConfigurationError, "The database '#{database}' is not configured" unless db

      response = configuration.http_post_proc.call(
        db.uri.to_s,
        db.headers,
        "#{query} FORMAT JSON" # always return JSON
      )

      raise DatabaseError, response.body unless response.success?

      Formatter.format(configuration.json_parser.parse(response.body))
    end
  end
end
