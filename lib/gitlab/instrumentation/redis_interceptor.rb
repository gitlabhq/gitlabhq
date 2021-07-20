# frozen_string_literal: true

module Gitlab
  module Instrumentation
    module RedisInterceptor
      APDEX_EXCLUDE = %w[brpop blpop brpoplpush bzpopmin bzpopmax xread xreadgroup].freeze

      def call(*args, &block)
        start = Gitlab::Metrics::System.monotonic_time # must come first so that 'start' is always defined
        instrumentation_class.instance_count_request
        instrumentation_class.redis_cluster_validate!(args.first)

        super(*args, &block)
      rescue ::Redis::BaseError => ex
        instrumentation_class.instance_count_exception(ex)
        raise ex
      ensure
        duration = Gitlab::Metrics::System.monotonic_time - start

        unless APDEX_EXCLUDE.include?(command_from_args(args))
          instrumentation_class.instance_observe_duration(duration)
        end

        if ::RequestStore.active?
          # These metrics measure total Redis usage per Rails request / job.
          instrumentation_class.increment_request_count
          instrumentation_class.add_duration(duration)
          instrumentation_class.add_call_details(duration, args)
        end
      end

      def write(command)
        measure_write_size(command) if ::RequestStore.active?
        super
      end

      def read
        result = super
        measure_read_size(result) if ::RequestStore.active?
        result
      end

      private

      def measure_write_size(command)
        size = 0

        # Mimic what happens in
        # https://github.com/redis/redis-rb/blob/f597f21a6b954b685cf939febbc638f6c803e3a7/lib/redis/connection/command_helper.rb#L8.
        # This count is an approximation that omits the Redis protocol overhead
        # of type prefixes, length prefixes and line endings.
        command.each do |x|
          size += begin
            if x.is_a? Array
              x.inject(0) { |sum, y| sum + y.to_s.bytesize }
            else
              x.to_s.bytesize
            end
          end
        end

        instrumentation_class.increment_write_bytes(size)
      end

      def measure_read_size(result)
        # The Connection::Ruby#read class can return one of four types of results from read:
        # https://github.com/redis/redis-rb/blob/f597f21a6b954b685cf939febbc638f6c803e3a7/lib/redis/connection/ruby.rb#L406
        #
        # 1. Error (exception, will not reach this line)
        # 2. Status (string)
        # 3. Integer (will be converted to string by to_s.bytesize and thrown away)
        # 4. "Binary" string (i.e. may contain zero byte)
        # 5. Array of binary string

        if result.is_a? Array
          # Redis can return nested arrays, e.g. from XRANGE or GEOPOS, so we use recursion here.
          result.each { |x| measure_read_size(x) }
        else
          # This count is an approximation that omits the Redis protocol overhead
          # of type prefixes, length prefixes and line endings.
          instrumentation_class.increment_read_bytes(result.to_s.bytesize)
        end
      end

      # That's required so it knows which GitLab Redis instance
      # it's interacting with in order to categorize accordingly.
      #
      def instrumentation_class
        @options[:instrumentation_class] # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end

      def command_from_args(args)
        command = args[0]
        command = command[0] if command.is_a?(Array)
        command.to_s.downcase
      end
    end
  end
end
