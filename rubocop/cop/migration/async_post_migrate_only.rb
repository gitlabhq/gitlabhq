# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Ensures that asynchronous index helper methods are only called from post migrations.
      class AsyncPostMigrateOnly < RuboCop::Cop::Base
        include MigrationHelpers

        MSG = 'Async index operations must be performed in a post-deployment migration.'

        FORBIDDEN_METHODS = %i[
          prepare_async_index
          unprepare_async_index
          prepare_async_index_removal
          unprepare_async_index
        ].freeze

        def on_send(node)
          return unless in_migration?(node)
          return unless time_enforced?(node)
          return unless FORBIDDEN_METHODS.include?(node.method_name)
          return if in_post_deployment_migration?(node)

          add_offense(node, message: MSG)
        end
      end
    end
  end
end
