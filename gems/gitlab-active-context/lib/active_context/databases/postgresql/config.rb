# frozen_string_literal: true

module ActiveContext
  module Databases
    module Postgresql
      module Config
        DEFAULT_CONNECT_TIMEOUT = 5
        DEFAULT_POOL_SIZE = 5

        def self.build_database_config(options)
          {
            adapter: 'postgresql',
            host: options[:host],
            port: options[:port],
            database: options[:database],
            user: options[:user],
            password: options[:password],
            connect_timeout: options.fetch(:connect_timeout, DEFAULT_CONNECT_TIMEOUT),
            pool: options.fetch(:pool_size, DEFAULT_POOL_SIZE),
            prepared_statements: false,
            advisory_locks: false,
            database_tasks: false
          }.compact
        end
      end
    end
  end
end
