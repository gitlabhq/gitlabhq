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
        BULK_OPERATIONS = [:upsert, :delete].freeze

        attr_reader :connection_pool, :options

        def initialize(options)
          @options = options.with_indifferent_access
          setup_connection_pool
        end

        def search(collection:, query:)
          raise ArgumentError, "Expected Query object, you used #{query.class}" unless query.is_a?(ActiveContext::Query)

          sql = Processor.transform(collection, query)
          res = with_connection do |conn|
            conn.execute(sql)
          end
          QueryResult.new(res)
        end

        def bulk_process(operations)
          failed_operations = []
          operations_by_collection = operations.group_by { |op| op.each_key.first }

          operations_by_collection.each do |collection_name, collection_operations|
            model = ar_model_for(collection_name)

            BULK_OPERATIONS.each do |operation_type|
              failed_ops = perform_bulk_operation(operation_type, model, collection_name, collection_operations)
              failed_operations.concat(failed_ops)
            end
          end

          failed_operations
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

        # rubocop:disable Rails/SkipsModelValidations -- bulk_upsert is more performant and we don't have validations
        def perform_bulk_operation(operation_type, model, collection_name, operations)
          data = operations.filter_map { |op| op[collection_name][operation_type] }

          return data if data.empty?

          case operation_type
          when :upsert
            upsert_data = prepare_upsert_data(data)
            model.transaction do
              upsert_data.each do |upsert_group|
                model.upsert_all(
                  upsert_group[:data],
                  unique_by: upsert_group[:unique_by],
                  update_only: upsert_group[:update_only_columns]
                )
              end
            end
          when :delete
            model.where(id: data).delete_all
          end

          []
        rescue StandardError => e
          ActiveContext::Logger.exception(e, message: "Error with #{operation_type} operation for #{collection_name}")
          operations.pluck(:ref)
        end
        # rubocop:enable Rails/SkipsModelValidations

        def prepare_upsert_data(data)
          data.group_by(&:keys).map do |columns, grouped_data|
            {
              unique_by: [:id, :partition_id],
              update_only_columns: columns - [:id, :partition_id],
              data: grouped_data
            }
          end
        end
      end
    end
  end
end
