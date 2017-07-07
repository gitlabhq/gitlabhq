require_relative '../model_helpers'

module RuboCop
  module Cop
    # Cop that prevents the use of `dependent: ...` in ActiveRecord models.
    class ActiveRecordDependent < RuboCop::Cop::Cop
      include ModelHelpers

      MSG = 'Do not use `dependent: to remove associated data, ' \
        'use foreign keys with cascading deletes instead'.freeze

      METHOD_NAMES = [:has_many, :has_one, :belongs_to].freeze

      def on_send(node)
        return unless in_model?(node)
        return unless METHOD_NAMES.include?(node.children[1])

        node.children.last.each_node(:pair) do |pair|
          key_name = pair.children[0].children[0]

          add_offense(pair, :expression) if key_name == :dependent
        end
      end
    end
  end
end
