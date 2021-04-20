# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      class AddColumnWithDefault < RuboCop::Cop::Cop
        include MigrationHelpers

        MSG = '`add_column_with_default` is deprecated, use `add_column` instead'

        def on_send(node)
          return unless in_migration?(node)

          name = node.children[1]

          add_offense(node, location: :selector) if name == :add_column_with_default
        end
      end
    end
  end
end
