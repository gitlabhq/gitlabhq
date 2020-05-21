# frozen_string_literal: true

require 'redis'

module Gitlab
  module Instrumentation
    class RedisDriver < ::Redis::Connection::Ruby
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

        ::Gitlab::Instrumentation::Redis.increment_write_bytes(size)
      end

      def measure_read_size(result)
        # The superclass can return one of four types of results from read:
        # https://github.com/redis/redis-rb/blob/f597f21a6b954b685cf939febbc638f6c803e3a7/lib/redis/connection/ruby.rb#L406
        #
        # 1. Error (exception, will not reach this line)
        # 2. Status (string)
        # 3. Integer (will be converted to string by to_s.bytesize and thrown away)
        # 4. "Binary" string (i.e. may contain zero byte)
        # 5. Array of binary string (recurses back into read)

        # Avoid double-counting array responses: the array elements themselves
        # are retrieved with 'read'.
        unless result.is_a? Array
          # This count is an approximation that omits the Redis protocol overhead
          # of type prefixes, length prefixes and line endings.
          ::Gitlab::Instrumentation::Redis.increment_read_bytes(result.to_s.bytesize)
        end
      end
    end
  end
end
