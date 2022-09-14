# frozen_string_literal: true

module RuboCop
  module Cop
    module Database
      # Checks for `rescue` blocks targeting the `ActiveRecord::QueryCanceled` class.
      #
      # @example
      #
      #   # bad
      #
      #   begin
      #     run_an_expensive_long_query
      #   rescue ActiveRecord::QueryCanceled
      #     try_something_else
      #   end
      #
      # @example
      #
      #   # good
      #
      #   run_cheap_queries_with_each_batch
      class RescueQueryCanceled < RuboCop::Cop::Base
        MSG = <<~EOF
          Avoid rescuing the `ActiveRecord::QueryCanceled` class.

          Using this pattern should be a very rare exception or a temporary patch only.
          Consider refactoring using less expensive queries and `each_batch`.
        EOF

        def on_resbody(node)
          return unless node.children.first

          rescue_args = node.children.first.children
          return unless rescue_args.any? { |a| targets_exception?(a) }

          add_offense(node)
        end

        def targets_exception?(rescue_arg_node)
          rescue_arg_node.const_name == 'ActiveRecord::QueryCanceled'
        end
      end
    end
  end
end
