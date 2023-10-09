# frozen_string_literal: true

module Gitlab
  module Observability
    extend self

    # Returns the GitLab Observability URL
    #
    def observability_url
      return ENV['OVERRIDE_OBSERVABILITY_URL'] if ENV['OVERRIDE_OBSERVABILITY_URL']
      # TODO Make observability URL configurable https://gitlab.com/gitlab-org/opstrace/opstrace-ui/-/issues/80
      return 'https://observe.staging.gitlab.com' if Gitlab.staging?

      'https://observe.gitlab.com'
    end

    def oauth_url
      "#{Gitlab::Observability.observability_url}/v1/auth/start"
    end

    def provisioning_url(project)
      "#{Gitlab::Observability.observability_url}/v3/tenant/#{project.id}"
    end

    # Returns true if the GitLab Observability UI (GOUI) feature flag is enabled
    #
    # @deprecated
    #
    def group_tab_enabled?(group = nil)
      return Feature.enabled?(:observability_group_tab, group) if group

      Feature.enabled?(:observability_group_tab)
    end
  end
end

Gitlab::Observability.prepend_mod_with('Gitlab::Observability')
