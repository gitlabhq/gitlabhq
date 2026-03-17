# frozen_string_literal: true

module ActiveContext
  module Databases
    module Postgresql
      module Config
        DEFAULT_CONNECT_TIMEOUT = 5
        DEFAULT_POOL_SIZE = 5

        def self.build_database_config(options)
          config = {
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
          }

          # Force TCP/IP connection by setting hostaddr when host is an IP address.
          # This prevents PostgreSQL from trying to use Unix sockets.
          # Only set hostaddr for IP addresses (not hostnames like 'localhost').
          config[:hostaddr] = options[:host] if ip_address?(options[:host])

          config.compact
        end

        def self.ip_address?(host)
          return false if host.nil? || host.start_with?('/')

          IPAddr.new(host)
          true
        rescue IPAddr::InvalidAddressError
          false
        end
      end
    end
  end
end
