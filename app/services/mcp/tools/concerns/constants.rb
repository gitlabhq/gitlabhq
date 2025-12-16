# frozen_string_literal: true

module Mcp
  module Tools
    module Concerns
      module Constants
        GROUP_ONLY_TYPES = %w[Epic Objective KeyResult].freeze
        PROJECT_AND_GROUP_TYPES = %w[Issue Task].freeze
        ALL_TYPES = (PROJECT_AND_GROUP_TYPES + GROUP_ONLY_TYPES).freeze

        URL_PATTERNS = {
          work_item: %r{\A/?(?:groups/)?(?<path>\S*)/-/work_items/(?<id>\d+)\z},
          quick_action: %r{^\s*/\w+}
        }.freeze

        VERSIONS = {
          v0_1_0: '0.1.0'
        }.freeze
      end
    end
  end
end
