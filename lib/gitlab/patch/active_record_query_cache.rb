# frozen_string_literal: true

# Fixes a bug where the query cache isn't aware of the shared
# ActiveRecord connection used in tests
# https://github.com/rails/rails/issues/36587

# To be removed with https://gitlab.com/gitlab-org/gitlab-ce/issues/64413

module Gitlab
  module Patch
    module ActiveRecordQueryCache
      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      def enable_query_cache!
        @query_cache_enabled[connection_cache_key(current_thread)] = true
        connection.enable_query_cache! if active_connection?
      end

      def disable_query_cache!
        @query_cache_enabled.delete connection_cache_key(current_thread)
        connection.disable_query_cache! if active_connection?
      end

      def query_cache_enabled
        @query_cache_enabled[connection_cache_key(current_thread)]
      end

      def active_connection?
        @thread_cached_conns[connection_cache_key(current_thread)]
      end

      private

      def current_thread
        @lock_thread || Thread.current
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables
    end
  end
end
