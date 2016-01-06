module Gitlab
  module Sherlock
    # A collection of transactions recorded by Sherlock.
    #
    # Method calls for this class are synchronized using a mutex to allow
    # sharing of a single Collection instance between threads (e.g. when using
    # Puma as a webserver).
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

      private

      def synchronize(&block)
        @mutex.synchronize(&block)
      end
    end
  end
end
