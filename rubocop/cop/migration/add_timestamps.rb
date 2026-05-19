# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks if 'add_timestamps' method is called with timezone information.
      class AddTimestamps < RuboCop::Cop::Base
        include MigrationHelpers

        RESTRICT_ON_SEND = %i[add_timestamps].freeze
        MSG = 'Do not use `add_timestamps`, use `add_timestamps_with_timezone` instead'

        # Check methods.
        def on_send(node)
          return unless in_migration?(node)

          add_offense(node.loc.selector)
        end
      end
    end
  end
end
