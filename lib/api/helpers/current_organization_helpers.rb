# frozen_string_literal: true

module API
  module Helpers
    # Safe resolvers for the Grape global Current.organization hook.
    #
    # safe_find_organization_actor_from_sources returns the authenticated
    # artifact the organization can be derived from: a User, or a
    # DeployToken (whose organization is reachable through its owner
    # project or group). It returns nil for other auth artifacts and for
    # unauthenticated requests, so the global hook can fall through to the
    # default organization without aborting the request.
    #
    # Runner- and cluster-agent-token endpoints set Current.organization
    # through their own per-endpoint helpers
    # (set_current_organization_from_runner,
    # set_current_organization_from_agent).
    # We do not look up those tokens here because Ci::Runner#find_by_token
    # (and similar partitioned lookups) emit a log line on partition miss
    # that prematurely evaluates the ApplicationContext lazy attributes.
    module CurrentOrganizationHelpers
      def safe_find_organization_actor_from_sources
        actor = find_user_from_sources
        actor.is_a?(User) || actor.is_a?(DeployToken) ? actor : nil
      rescue Gitlab::Auth::UnauthorizedError, Gitlab::Auth::AuthenticationError
        nil
      end
    end
  end
end
