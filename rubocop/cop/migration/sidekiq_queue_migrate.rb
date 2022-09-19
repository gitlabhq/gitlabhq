# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks if sidekiq_queue_migrate is used in a regular
      # (not post-deployment) migration.
      class SidekiqQueueMigrate < RuboCop::Cop::Base
        include MigrationHelpers

        MSG = '`sidekiq_queue_migrate` must only be used in post-deployment migrations'

        def on_def(node)
          return unless in_migration?(node) && !in_post_deployment_migration?(node)

          node.each_descendant(:send) do |send_node|
            send_method = send_node.children[1]

            if send_method == :sidekiq_queue_migrate
              add_offense(send_node.loc.selector)
            end
          end
        end
      end
    end
  end
end
