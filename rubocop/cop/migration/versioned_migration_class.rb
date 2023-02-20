# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      class VersionedMigrationClass < RuboCop::Cop::Base
        include MigrationHelpers

        ENFORCED_SINCE = 2023_01_12_00_00_00
        DOC_LINK = "https://docs.gitlab.com/ee/development/migration_style_guide.html#migration-helpers-and-versioning"

        MSG_INHERIT = "Don't inherit from ActiveRecord::Migration or old versions of Gitlab::Database::Migration. " \
                      "Use Gitlab::Database::Migration[2.1] instead. See #{DOC_LINK}."

        MSG_INCLUDE = "Don't include migration helper modules directly. " \
                      "Inherit from Gitlab::Database::Migration[2.1] instead. See #{DOC_LINK}."

        GITLAB_MIGRATION_CLASS = 'Gitlab::Database::Migration'
        ACTIVERECORD_MIGRATION_CLASS = 'ActiveRecord::Migration'
        CURRENT_MIGRATION_VERSION = 2.1 # Should be the same value as Gitlab::Database::Migration.current_version

        def_node_search :includes_helpers?, <<~PATTERN
        (send nil? :include
          (const
            (const
              (const nil? :Gitlab) :Database) :MigrationHelpers))
        PATTERN

        def on_class(node)
          return unless relevant_migration?(node)
          return unless activerecord_migration_class?(node) || old_version_migration_class?(node)

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

        # Returns true for any parent class of format Gitlab::Database::Migration[version] if version < current_version
        def old_version_migration_class?(class_node)
          parent_class_node = class_node.parent_class
          return false unless parent_class_node.send_type? && parent_class_node.arguments.last.float_type?
          return false unless parent_class_node.children[0].const_name == GITLAB_MIGRATION_CLASS

          parent_class_node.arguments[0].value < CURRENT_MIGRATION_VERSION
        end
      end
    end
  end
end
