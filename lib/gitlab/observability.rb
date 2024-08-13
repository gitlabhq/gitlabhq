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

    def should_enable_observability_auth_scopes?(resource)
      # Enable the needed oauth scopes if tracing is enabled.
      if resource.is_a?(Group) || resource.is_a?(Project)
        return Feature.enabled?(:observability_features, resource.root_ancestor)
      end

      false
    end
  end
end

Gitlab::Observability.prepend_mod_with('Gitlab::Observability')
