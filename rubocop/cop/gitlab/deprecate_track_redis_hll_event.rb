# frozen_string_literal: true

require 'rack/utils'

module RuboCop
  module Cop
    module Gitlab
      # This cop prevents from using deprecated `track_redis_hll_event` method.
      #
      # @example
      #
      # # bad
      #  track_redis_hll_event :show, name: 'p_analytics_valuestream'
      #
      # # good
      #   track_event :show, name: 'g_analytics_valuestream', destinations: [:redis_hll]
      class DeprecateTrackRedisHLLEvent < RuboCop::Cop::Base
        MSG = '`track_redis_hll_event` is deprecated. Use `track_event` helper instead. ' \
              'See https://docs.gitlab.com/ee/development/service_ping/implement.html#add-new-events'

        def_node_matcher :track_redis_hll_event_used?, <<~PATTERN
          (send _ :track_redis_hll_event ...)
        PATTERN

        def on_send(node)
          return unless track_redis_hll_event_used?(node)

          add_offense(node.loc.selector)
        end
      end
    end
  end
end
