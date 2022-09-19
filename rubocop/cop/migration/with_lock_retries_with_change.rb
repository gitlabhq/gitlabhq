# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that prevents usage of `with_lock_retries` within the `change` method.
      class WithLockRetriesWithChange < RuboCop::Cop::Base
        include MigrationHelpers

        MSG = '`with_lock_retries` cannot be used within `change` so you must manually define ' \
          'the `up` and `down` methods in your migration class and use `with_lock_retries` in both methods'

        def on_send(node)
          return unless in_migration?(node)
          return unless node.children[1] == :with_lock_retries

          node.each_ancestor(:def) do |def_node|
            add_offense(def_node.loc.name) if def_node.method_name == :change
          end
        end
      end
    end
  end
end
