# frozen_string_literal: true

module RuboCop
  module Cop
    module Database
      class EstablishConnection < RuboCop::Cop::Base
        MSG = "Don't establish new database connections, as this slows down " \
          'tests and may result in new connections using an incorrect configuration'

        def_node_matcher :establish_connection?, <<~PATTERN
          (send (const ...) :establish_connection ...)
        PATTERN

        def on_send(node)
          add_offense(node) if establish_connection?(node)
        end
      end
    end
  end
end
