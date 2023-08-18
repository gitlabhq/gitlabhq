# frozen_string_literal: true

module ClickHouse
  module Client
    class Database
      attr_reader :database

      def initialize(database:, url:, username:, password:, variables: {})
        @database = database
        @url = url
        @username = username
        @password = password
        @variables = {
          database: database,
          enable_http_compression: 1 # enable HTTP compression by default
        }.merge(variables).freeze
      end

      def uri
        @uri ||= begin
          parsed = Addressable::URI.parse(@url)
          parsed.query_values = @variables
          parsed
        end
      end

      def headers
        @headers ||= {
          'X-ClickHouse-User' => @username,
          'X-ClickHouse-Key' => @password,
          'X-ClickHouse-Format' => 'JSON', # always return JSON data
          'Content-Encoding' => 'gzip' # tell the server that we send compressed data
        }.freeze
      end
    end
  end
end
