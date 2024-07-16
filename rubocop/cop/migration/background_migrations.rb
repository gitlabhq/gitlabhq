# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      class BackgroundMigrations < RuboCop::Cop::Base
        include MigrationHelpers

        MSG = 'Background migrations are deprecated. Please use a batched background migration instead. '\
              'More info: https://docs.gitlab.com/ee/development/database/batched_background_migrations.html'

        def on_send(node)
          name = node.children[1]

          disabled_methods = %i[
            queue_background_migration_jobs_by_range_at_intervals
            requeue_background_migration_jobs_by_range_at_intervals
            migrate_in
          ]

          add_offense(node.loc.selector) if disabled_methods.include? name
        end
      end
    end
  end
end
