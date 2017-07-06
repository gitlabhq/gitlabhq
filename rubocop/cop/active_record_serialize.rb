require_relative '../model_helpers'

module RuboCop
  module Cop
    # Cop that prevents the use of `serialize` in ActiveRecord models.
    class ActiveRecordSerialize < RuboCop::Cop::Cop
      include ModelHelpers

      MSG = 'Do not store serialized data in the database, use separate columns and/or tables instead'.freeze

      def on_send(node)
        return unless in_model?(node)

        add_offense(node, :selector) if node.children[1] == :serialize
      end
    end
  end
end
