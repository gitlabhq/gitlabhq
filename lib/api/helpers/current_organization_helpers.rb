# frozen_string_literal: true

module API
  module Helpers
    # Safe resolvers for the Grape global Current.organization hook.
    #
    # safe_find_user_from_sources returns nil for non-User auth artifacts
    # (deploy tokens) and unauthenticated requests, so the global hook can
    # fall through to the default organization without aborting the request.
    #
    # Runner-, deploy-, and cluster-agent-token endpoints continue to set
    # Current.organization through their existing per-endpoint helpers
    # (set_current_organization_from_runner, set_current_organization).
    # We do not look up those tokens here because Ci::Runner#find_by_token
    # (and similar partitioned lookups) emit a log line on partition miss
    # that prematurely evaluates the ApplicationContext lazy attributes.
    module CurrentOrganizationHelpers
      def safe_find_user_from_sources
        user = find_user_from_sources
        user.is_a?(User) ? user : nil
      rescue Gitlab::Auth::UnauthorizedError, Gitlab::Auth::AuthenticationError
        nil
      end
    end
  end
end
