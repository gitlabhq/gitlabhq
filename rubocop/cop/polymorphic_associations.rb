require_relative '../model_helpers'

module RuboCop
  module Cop
    # Cop that prevents the use of polymorphic associations
    class PolymorphicAssociations < RuboCop::Cop::Cop
      include ModelHelpers

      MSG = 'Do not use polymorphic associations, use separate tables instead'.freeze

      def on_send(node)
        return unless in_model?(node)
        return unless node.children[1] == :belongs_to

        node.children.last.each_node(:pair) do |pair|
          key_name = pair.children[0].children[0]

          add_offense(pair, :expression) if key_name == :polymorphic
        end
      end
    end
  end
end
