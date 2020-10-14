# frozen_string_literal: true

module RuboCop
  module Cop
    module Graphql
      class GIDExpectedType < RuboCop::Cop::Cop
        MSG = 'Add an expected_type parameter to #object_from_id calls if possible.'

        def_node_search :id_from_object?, <<~PATTERN
          (send ... :object_from_id (...))
        PATTERN

        def on_send(node)
          return unless id_from_object?(node)

          add_offense(node)
        end
      end
    end
  end
end
