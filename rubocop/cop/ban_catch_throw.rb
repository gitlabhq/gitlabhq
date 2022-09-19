# frozen_string_literal: true

module RuboCop
  module Cop
    # Bans the use of 'catch/throw', as exceptions are better for errors and
    # they are equivalent to 'goto' for flow control, with all the problems
    # that implies.
    #
    # @example
    #   # bad
    #   catch(:error) do
    #     throw(:error)
    #   end
    #
    #   # good
    #   begin
    #     raise StandardError
    #   rescue StandardError => err
    #     # ...
    #   end
    #
    class BanCatchThrow < RuboCop::Cop::Base
      MSG = "Do not use catch or throw unless a gem's API demands it."

      def on_send(node)
        receiver, method_name, _ = *node

        return unless receiver.nil? && %i[catch throw].include?(method_name)

        add_offense(node)
      end
    end
  end
end
