require 'gitlab/styles/rubocop/model_helpers'

module RuboCop
  module Cop
    module Gitlab
      class HasManyThroughScope < RuboCop::Cop::Cop
        include ::Gitlab::Styles::Rubocop::ModelHelpers

        MSG = 'Always provide an explicit scope calling auto_include(false) when using has_many :through'.freeze

        def_node_search :through?, <<~PATTERN
          (pair (sym :through) _)
        PATTERN

        def_node_matcher :has_many_through?, <<~PATTERN
          (send nil? :has_many ... #through?)
        PATTERN

        def_node_search :disables_auto_include?, <<~PATTERN
          (send _ :auto_include false)
        PATTERN

        def_node_matcher :scope_disables_auto_include?, <<~PATTERN
          (block (send nil? :lambda) _ #disables_auto_include?)
        PATTERN

        def on_send(node)
          return unless in_model?(node)
          return unless has_many_through?(node)

          target = node
          scope_argument = node.children[3]

          if scope_argument.children[0].children.last == :lambda
            return if scope_disables_auto_include?(scope_argument)

            target = scope_argument
          end

          add_offense(target, location: :expression)
        end
      end
    end
  end
end
