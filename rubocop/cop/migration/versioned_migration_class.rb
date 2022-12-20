# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      class VersionedMigrationClass < RuboCop::Cop::Base
        include MigrationHelpers

        ENFORCED_SINCE = 2021_09_02_00_00_00
        CURRENT_DATABASE_MIGRATION_CLASS = 'Gitlab::Database::Migration[2.1]'

        MSG_INHERIT = 'Don\'t inherit from ActiveRecord::Migration but use Gitlab::Database::Migration[2.1] instead. See https://docs.gitlab.com/ee/development/migration_style_guide.html#migration-helpers-and-versioning.'
        MSG_INCLUDE = 'Don\'t include migration helper modules directly. Inherit from Gitlab::Database::Migration[2.1] instead. See https://docs.gitlab.com/ee/development/migration_style_guide.html#migration-helpers-and-versioning.'

        ACTIVERECORD_MIGRATION_CLASS = 'ActiveRecord::Migration'

        def_node_search :includes_helpers?, <<~PATTERN
        (send nil? :include
          (const
            (const
              (const nil? :Gitlab) :Database) :MigrationHelpers))
        PATTERN

        def on_class(node)
          return unless relevant_migration?(node)
          return unless activerecord_migration_class?(node)

          add_offense(node, message: MSG_INHERIT)
        end

        def on_send(node)
          return unless relevant_migration?(node)

          add_offense(node, message: MSG_INCLUDE) if includes_helpers?(node)
        end

        private

        def relevant_migration?(node)
          in_migration?(node) && version(node) >= ENFORCED_SINCE
        end

        def activerecord_migration_class?(node)
          superclass(node) == ACTIVERECORD_MIGRATION_CLASS
        end

        def superclass(class_node)
          _, *others = class_node.descendants

          others.find { |node| node.const_type? && node&.const_name != 'Types' }&.const_name
        end
      end
    end
  end
end
