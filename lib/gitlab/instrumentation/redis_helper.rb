# frozen_string_literal: true

module Gitlab
  module Instrumentation
    module RedisHelper
      APDEX_EXCLUDE = %w[brpop blpop brpoplpush bzpopmin bzpopmax command xread xreadgroup].freeze

      def instrument_call(commands, instrumentation_class, pipelined = false)
        start = Gitlab::Metrics::System.monotonic_time # must come first so that 'start' is always defined
        instrumentation_class.instance_count_request(commands.size)
        instrumentation_class.instance_count_pipelined_request(commands.size) if pipelined

        if !instrumentation_class.redis_cluster_validate!(commands) && ::RequestStore.active?
          instrumentation_class.increment_cross_slot_request_count
        end

        yield
      rescue ::Redis::BaseError, ::RedisClient::Error => ex
        if ex.message.start_with?('MOVED', 'ASK')
          instrumentation_class.instance_count_cluster_redirection(ex)
        else
          instrumentation_class.instance_count_exception(ex)
        end

        instrumentation_class.log_exception(ex)
        raise ex
      ensure
        duration = Gitlab::Metrics::System.monotonic_time - start

        unless exclude_from_apdex?(commands)
          commands.each { instrumentation_class.instance_observe_duration(duration / commands.size) }
        end

        if ::RequestStore.active?
          # These metrics measure total Redis usage per Rails request / job.
          instrumentation_class.increment_request_count(commands.size)
          instrumentation_class.add_duration(duration)
          instrumentation_class.add_call_details(duration, commands)
        end
      end

      def measure_write_size(command, instrumentation_class)
        size = 0

        # Mimic what happens in
        # https://github.com/redis/redis-rb/blob/f597f21a6b954b685cf939febbc638f6c803e3a7/lib/redis/connection/command_helper.rb#L8.
        # This count is an approximation that omits the Redis protocol overhead
        # of type prefixes, length prefixes and line endings.
        command.each do |x|
          size += if x.is_a? Array
                    x.inject(0) { |sum, y| sum + y.to_s.bytesize }
                  else
                    x.to_s.bytesize
                  end
        end

        instrumentation_class.increment_write_bytes(size)
      end

      def measure_read_size(result, instrumentation_class)
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
          result.each { |x| measure_read_size(x, instrumentation_class) }
        else
          # This count is an approximation that omits the Redis protocol overhead
          # of type prefixes, length prefixes and line endings.
          instrumentation_class.increment_read_bytes(result.to_s.bytesize)
        end
      end

      def exclude_from_apdex?(commands)
        commands.any? { |command| APDEX_EXCLUDE.include?(command.first.to_s.downcase) }
      end
    end
  end
end
