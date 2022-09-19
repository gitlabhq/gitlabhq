# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      class BackgroundMigrationRecord < RuboCop::Cop::Base
        include MigrationHelpers

        MSG = <<~MSG
          Don't use or inherit from ActiveRecord::Base.
          Use ::ApplicationRecord or ::Ci::ApplicationRecord to ensure the correct database is used.
          See https://docs.gitlab.com/ee/development/database/batched_background_migrations.html#accessing-data-for-multiple-databases.
        MSG

        def_node_matcher :inherits_from_active_record_base?, <<~PATTERN
          (class _ (const (const _ :ActiveRecord) :Base) _)
        PATTERN

        def_node_search :class_new_active_record_base?, <<~PATTERN
          (send (const _ :Class) :new (const (const _ :ActiveRecord) :Base) ...)
        PATTERN

        def on_class(node)
          return unless in_background_migration?(node)
          return unless inherits_from_active_record_base?(node)

          add_offense(node)
        end

        def on_send(node)
          return unless in_background_migration?(node)
          return unless class_new_active_record_base?(node)

          add_offense(node)
        end
      end
    end
  end
end
