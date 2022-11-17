# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks that no background batched migration helpers are called by regular migrations.
      class BatchMigrationsPostOnly < RuboCop::Cop::Base
        include MigrationHelpers

        MSG = "This method must only be used in post-deployment migrations."

        FORBIDDEN_METHODS = %w[
          ensure_batched_background_migration_is_finished
          queue_batched_background_migration
          delete_batched_background_migration
          finalize_batched_background_migration
        ].freeze

        SYMBOLIZED_MATCHER = FORBIDDEN_METHODS.map { |w| ":#{w}" }.join(' | ')

        def_node_matcher :on_forbidden_method, <<~PATTERN
          (send nil? {#{SYMBOLIZED_MATCHER}} ...)
        PATTERN

        def on_send(node)
          on_forbidden_method(node) do
            break if in_post_deployment_migration?(node)

            add_offense(node, message: MSG)
          end
        end
      end
    end
  end
end
