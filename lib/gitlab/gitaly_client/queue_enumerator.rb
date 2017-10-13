module Gitlab
  module GitalyClient
    class QueueEnumerator
      def initialize
        @queue = Queue.new
      end

      def push(elem)
        @queue << elem
      end

      def close
        push(:close)
      end

      def each
        return enum_for(:each) unless block_given?

        loop do
          elem = @queue.pop
          break if elem == :close

          yield elem
        end
      end
    end
  end
end
