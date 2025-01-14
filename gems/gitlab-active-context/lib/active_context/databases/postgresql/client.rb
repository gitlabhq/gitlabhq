# frozen_string_literal: true

module ActiveContext
  module Databases
    module Postgresql
      class Client
        include ActiveContext::Databases::Concerns::Client

        DEFAULT_POOL_SIZE = 5
        DEFAULT_POOL_TIMEOUT = 5

        def initialize(options)
          @options = options
          @pool = ConnectionPool.new(
            size: options.fetch(:pool_size, DEFAULT_POOL_SIZE),
            timeout: options.fetch(:pool_timeout, DEFAULT_POOL_TIMEOUT)
          ) do
            PG.connect(connection_params)
          end
        end

        def search(_query)
          with_connection do |conn|
            res = conn.exec('SELECT * FROM pg_stat_activity')
            QueryResult.new(res)
          end
        end

        private

        def with_connection
          @pool.with do |conn|
            yield(conn)
          end
        end

        def close
          @pool&.shutdown(&:close)
        end

        def connection_params
          {
            host: options[:host],
            port: options[:port],
            dbname: options[:database],
            user: options[:username],
            password: options[:password],
            connect_timeout: options.fetch(:connect_timeout, 5)
          }.compact
        end
      end
    end
  end
end
