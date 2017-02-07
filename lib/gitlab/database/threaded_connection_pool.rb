module Gitlab
  module Database
    class ThreadedConnectionPool
      def self.with_pool(pool_size)
        pool = new(pool_size)

        yield(pool)

      ensure
        pool.join
        pool.close
      end

      def initialize(pool_size)
        config = ActiveRecord::Base.configurations[Rails.env]
        @ar_pool = ActiveRecord::Base.establish_connection(
          config.merge(pool: pool_size))
        @workers = []
        @mutex = Mutex.new
      end

      def execute_async(sql)
        @mutex.synchronize do
          @workers << Thread.new do
            @ar_pool.with_connection do |connection|
              connection.execute(sql)
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

        threads.each(&:join)
      end

      def close
        @ar_pool.disconnect!
      end
    end
  end
end
