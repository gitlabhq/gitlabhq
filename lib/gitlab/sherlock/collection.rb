module Gitlab
  module Sherlock
    class Collection
      include Enumerable

      def initialize
        @transactions = []
        @mutex = Mutex.new
      end

      def add(transaction)
        synchronize { @transactions << transaction }
      end

      alias_method :<<, :add

      def each(&block)
        synchronize { @transactions.each(&block) }
      end

      def clear
        synchronize { @transactions.clear }
      end

      def empty?
        synchronize { @transactions.empty? }
      end

      def find_transaction(id)
        find { |trans| trans.id == id }
      end

      def newest_first
        sort { |a, b| b.finished_at <=> a.finished_at }
      end

      def synchronize(&block)
        @mutex.synchronize(&block)
      end
    end
  end
end
