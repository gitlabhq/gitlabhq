# frozen_string_literal: true

module Gitlab
  module Redis
    class MultiStoreConnectionPool < ::ConnectionPool
      # We intercept the returned connection and borrow the connections
      # before yielding the block.
      def with
        super do |conn|
          next yield conn unless conn.respond_to?(:with_borrowed_connection)

          conn.with_borrowed_connection do
            yield conn
          end
        end
      end

      alias_method :then, :with
    end
  end
end
