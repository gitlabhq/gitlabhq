# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks that no background batched migration helpers are called by regular migrations.
      class SchemaAdditionMethodsNoPost < RuboCop::Cop::Base
        include MigrationHelpers

        MSG = "This method may not be used in post migrations. Please see documentation here: https://docs.gitlab.com/ee/development/migration_style_guide.html#choose-an-appropriate-migration-type"

        FORBIDDEN_METHODS = %w[
          add_column
          create_table
        ].freeze

        SYMBOLIZED_MATCHER = FORBIDDEN_METHODS.map { |w| ":#{w}" }.join(' | ')

        def_node_matcher :on_forbidden_method, <<~PATTERN
          (send nil? {#{SYMBOLIZED_MATCHER}} ...)
        PATTERN

        def on_send(node)
          return unless time_enforced?(node)

          on_forbidden_method(node) do
            add_offense(node, message: MSG)
          end
        end
      end
    end
  end
end
