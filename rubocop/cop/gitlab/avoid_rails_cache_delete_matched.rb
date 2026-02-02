# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Checks for `Rails.cache.delete_matched` usage.
      #
      # `Rails.cache.delete_matched` scans the entire Redis cluster to find keys
      # matching the pattern, which can cause severe performance issues, timeouts,
      # and production incidents in large-scale applications.
      #
      # @example
      #
      #   # bad
      #   Rails.cache.delete_matched("users/*/feature_enabled/*")
      #
      #   # bad
      #   Rails.cache.delete_matched(
      #     "some/key/*"
      #   )
      #
      #   # good - delete specific cache keys
      #   Rails.cache.delete("some/key")
      #
      #   # good - redesign caching strategy to avoid wildcard deletions
      #   # Use a versioned cache key approach:
      #   def cache_key
      #     "some/key/id/v#{cache_version}"
      #   end
      #
      #   def cache_version
      #     # Increment version when cache needs invalidation
      #     user.cache_version
      #   end
      class AvoidRailsCacheDeleteMatched < ::RuboCop::Cop::Base
        MSG = 'Avoid `Rails.cache.delete_matched` as it scans the entire Redis cluster, ' \
          'causing performance issues and timeouts. Consider using explicit cache key deletion with ' \
          '`Rails.cache.delete` or redesigning the caching strategy.'

        # @!method rails_cache_delete_matched?(node)
        def_node_matcher :rails_cache_delete_matched?, <<~PATTERN
          (send
            (send (const {nil? cbase} :Rails) :cache)
            :delete_matched ...
          )
        PATTERN

        def on_send(node)
          return unless rails_cache_delete_matched?(node)

          add_offense(node)
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end
