# frozen_string_literal: true

module RuboCop
  module Cop
    module Database
      # Avoid using connection.execute for read-only queries.
      #
      # @example
      #
      #   # bad
      #   class MyClass < ApplicationRecord
      #     def all
      #       connection.execute('SELECT * FROM my_table') # This goes to the primary db node
      #     end
      #   end
      #
      #   # good
      #   class MyClass < ApplicationRecord
      #     def all
      #       connection.select_all('SELECT * FROM my_table') # This goes to a read replica
      #     end
      #   end
      class AvoidUsingConnectionExecute < RuboCop::Cop::Base
        MSG = "The `connection.execute` method always runs SQL statements on the primary database node. " \
          "To ensure queries are routed to the appropriate node (replica or primary), use operations like " \
          "`.select_all` or `.select_rows` for reads and `.insert` or `.update` for write operations."

        # @!method connection_execute?(node)
        def_node_matcher :connection_execute?, <<~PATTERN
          (send (send nil? :connection) :execute ...)
        PATTERN

        def on_send(node)
          add_offense(node) if connection_execute?(node)
        end

        alias_method :on_csend, :on_send
      end
    end
  end
end
