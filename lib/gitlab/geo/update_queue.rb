module Gitlab
  module Geo
    class UpdateQueue
      BATCH_SIZE = 250
      NAMESPACE = 'geo:gitlab'

      def initialize(queue)
        @queue = queue
      end

      def store(data)
        redis.rpush(@queue, data.to_json)
        expire_queue_size!
      end

      def first
        data = fetch(0, 0)
        data.first unless data.empty?
      end

      def last
        data = fetch(-1, -1)
        data.first unless data.empty?
      end

      def fetch_batched_data
        projects = []
        bsize = batch_size

        redis.multi do
          projects = redis.lrange(@queue, 0, bsize - 1)
          redis.ltrim(@queue, bsize, -1)
        end

        expire_queue_size!
        deserialize(projects.value)
      end

      def store_batched_data(projects)
        redis.pipelined do
          projects.reverse_each do |project|
            # enqueue again to the head of the queue
            redis.lpush(@queue, project.to_json)
          end
        end
        expire_queue_size!
      end

      def batch_size
        queue_size > BATCH_SIZE ? BATCH_SIZE : queue_size
      end

      def queue_size
        @queue_size ||= fetch_queue_size
      end

      def empty?
        queue_size == 0
      end

      def empty!
        redis.del(@queue)
      end

      protected

      def fetch(start, stop)
        deserialize(redis.lrange(@queue, start, stop))
      end

      def fetch_queue_size
        redis.llen(@queue)
      end

      def expire_queue_size!
        @queue_size = nil
      end

      def deserialize(data)
        data.map! { |item| JSON.parse(item) } unless data.empty?
        data
      end

      def redis
        self.class.redis
      end

      def self.redis_connection
        redis_config_file = Rails.root.join('config', 'resque.yml')

        redis_url_string = if File.exist?(redis_config_file)
                             YAML.load_file(redis_config_file)[Rails.env]
                           else
                             'redis://localhost:6379'
                           end

        ::Redis::Namespace.new(NAMESPACE, redis: ::Redis.new(url: redis_url_string))
      end

      def self.redis
        @redis ||= redis_connection
      end
    end
  end
end
