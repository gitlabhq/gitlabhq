# frozen_string_literal: true

module ActiveContext
  module Databases
    module Postgresql
      class Client
        include ActiveContext::Databases::Concerns::Client

        class << self
          attr_accessor :default_connection_pool
        end

        DEFAULT_POOL_SIZE = 5
        DEFAULT_CONNECT_TIMEOUT = 5

        attr_reader :connection_pool, :options

        def initialize(options)
          @options = options
          setup_connection_pool
        end

        def search(_query)
          with_connection do |conn|
            res = conn.execute('SELECT * FROM pg_stat_activity')
            QueryResult.new(res)
          end
        end

        # Provides raw PostgreSQL connection
        def with_raw_connection(&block)
          handle_connection(raw_connection: true, &block)
        end

        # Provides Rails-wrapped connection for using ActiveRecord methods
        def with_connection(&block)
          handle_connection(raw_connection: false, &block)
        end

        # Creates an ActiveRecord model for a specific table and yields it within the connection context
        # @param table_name [String] The name of the table to create a model for
        # @yield [Class] A dynamically created ActiveRecord model class with the correct connection
        def with_model_for(table_name)
          model_class = Class.new(::ActiveRecord::Base) do
            self.table_name = table_name

            def self.name
              "ActiveContext::Model::#{table_name.classify}"
            end

            def self.to_s
              name
            end
          end

          with_connection do |conn|
            model_class.define_singleton_method(:connection) { conn }
            yield model_class
          end
        end

        # For backward compatibility and simpler queries
        def ar_model_for(table_name)
          klass = nil
          with_model_for(table_name) do |model_class|
            klass = model_class
          end
          klass
        end

        private

        def handle_connection(raw_connection: false)
          connection_pool.with_connection do |conn|
            yield(raw_connection ? conn.raw_connection : conn)
          rescue PG::Error, ::ActiveRecord::StatementInvalid => e
            handle_error(e)
          end
        end

        def handle_error(error)
          ActiveContext::Logger.exception(error, message: 'Database error occurred')
          raise error
        end

        def setup_connection_pool
          model_class = create_connection_model
          model_class.establish_connection(build_database_config.stringify_keys)
          @connection_pool = model_class.connection_pool
        end

        def create_connection_model
          Class.new(::ActiveRecord::Base) do
            self.abstract_class = true

            def self.name
              "ActiveContext::ConnectionPool::#{object_id}"
            end

            def self.to_s
              name
            end
          end
        end

        def build_database_config
          {
            adapter: 'postgresql',
            host: options[:host],
            port: options[:port],
            database: options[:database],
            username: options[:username],
            password: options[:password],
            connect_timeout: options.fetch(:connect_timeout, DEFAULT_CONNECT_TIMEOUT),
            pool: calculate_pool_size,
            prepared_statements: false,
            advisory_locks: false,
            database_tasks: false # This signals Rails that this is an auxiliary database
          }.compact
        end

        def calculate_pool_size
          options[:pool_size] || DEFAULT_POOL_SIZE
        end

        def close
          connection_pool&.disconnect!
        end
      end
    end
  end
end
