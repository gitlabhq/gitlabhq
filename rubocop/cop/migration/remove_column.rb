# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks if remove_column is used in a regular (not
      # post-deployment) migration.
      class RemoveColumn < RuboCop::Cop::Base
        include MigrationHelpers

        MSG = '`remove_column` must only be used in post-deployment migrations'

        def on_def(node)
          def_method = node.children[0]

          return unless in_migration?(node) && !in_post_deployment_migration?(node)
          return unless def_method == :change || def_method == :up

          node.each_descendant(:send) do |send_node|
            send_method = send_node.children[1]

            if send_method == :remove_column
              add_offense(send_node.loc.selector)
            end
          end
        end
      end
    end
  end
end
