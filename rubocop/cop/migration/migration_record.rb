# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      class MigrationRecord < RuboCop::Cop::Base
        include MigrationHelpers

        ENFORCED_SINCE = 2022_04_26_00_00_00

        MSG = <<~MSG
          Don't inherit from ActiveRecord::Base or ApplicationRecord but use MigrationRecord instead.
          See https://docs.gitlab.com/ee/development/database/migrations_for_multiple_databases.html#example-usage-of-activerecord-classes.
        MSG

        def_node_search :inherits_from_active_record_base?, <<~PATTERN
          (class _ (const (const _ :ActiveRecord) :Base) _)
        PATTERN

        def_node_search :inherits_from_application_record?, <<~PATTERN
          (class _ (const _ :ApplicationRecord) _)
        PATTERN

        def on_class(node)
          return unless relevant_migration?(node)
          return unless inherits_from_active_record_base?(node) || inherits_from_application_record?(node)

          add_offense(node)
        end

        private

        def relevant_migration?(node)
          in_migration?(node) && version(node) >= ENFORCED_SINCE
        end
      end
    end
  end
end
