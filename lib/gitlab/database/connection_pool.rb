module Gitlab
  module Database
    class ConnectionPool
      def self.with_pool(pool_size)
        pool = new(pool_size)

        yield(pool)

      ensure
        pool.join
        pool.close
      end

      attr_reader :ar_pool, :workers

      def initialize(pool_size)
        @ar_pool = create_connection_pool(pool_size)
        @workers = []
        @mutex = Mutex.new
      end

      def pool_size
        @ar_pool.spec.config[:pool]
      end

      # Pass `method: :exec_query` if we want unified result from query
      # across PostgreSQL and MySQL
      def execute_async(sql, method: :execute)
        @mutex.synchronize do
          @workers << Thread.new do
            @ar_pool.with_connection do |connection|
              connection.public_send(method, sql)
            end
          end
        end
      end

      def join
        threads = nil

        @mutex.synchronize do
          threads = @workers.dup
          @workers.clear
        end

        threads.map(&:value)
      end

      def close
        @ar_pool.disconnect!
      end

      def closed?
        !@ar_pool.connected?
      end

      def inspect
        "#<#{self.class.name}" \
          " pool_size=#{pool_size}" \
          " workers_size=#{workers.size}>"
      end

      private

      def create_connection_pool(pool_size)
        # See activerecord-4.2.7.1/lib/active_record/connection_adapters/connection_specification.rb
        env = Rails.env
        original_config = ActiveRecord::Base.configurations
        env_config = original_config[env].merge('pool' => pool_size)
        config = original_config.merge(env => env_config)

        spec =
          ActiveRecord::
            ConnectionAdapters::
            ConnectionSpecification::Resolver.new(config).spec(env.to_sym)

        ActiveRecord::ConnectionAdapters::ConnectionPool.new(spec)
      end
    end
  end
end
