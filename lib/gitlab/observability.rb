# frozen_string_literal: true

module Gitlab
  module Observability
    extend self

    # Returns the GitLab Observability URL
    #
    def observability_url
      return ENV['OVERRIDE_OBSERVABILITY_QUERY_URL'] if ENV['OVERRIDE_OBSERVABILITY_QUERY_URL']
      # TODO Make observability URL configurable https://gitlab.com/gitlab-org/opstrace/opstrace-ui/-/issues/80
      # Dev, test and staging instances can all point to `observe.staging.gitlab.com` by default
      return 'https://observe.staging.gitlab.com' if Gitlab.staging? || Gitlab.dev_or_test_env?

      'https://observe.gitlab.com'
    end

    def observability_ingest_url
      return ENV['OVERRIDE_OBSERVABILITY_INGEST_URL'] if ENV['OVERRIDE_OBSERVABILITY_INGEST_URL']
      # TODO Make observability URL configurable https://gitlab.com/gitlab-org/opstrace/opstrace-ui/-/issues/80
      # Dev, test and staging instances can all point to `observe.staging.gitlab.com` by default
      return 'https://observe.staging.gitlab.com' if Gitlab.staging? || Gitlab.dev_or_test_env?

      'https://observe.gitlab.com'
    end

    def alerts_url
      "#{Gitlab::Observability.observability_url}/observability/v1/alerts"
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
