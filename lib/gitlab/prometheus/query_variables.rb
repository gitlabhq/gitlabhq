# frozen_string_literal: true

module Gitlab
  module Prometheus
    module QueryVariables
      def self.call(environment)
        deployment_platform = environment.deployment_platform
        namespace = deployment_platform&.namespace_for(environment.project) ||
          deployment_platform&.actual_namespace || ''

        {
          ci_environment_slug: environment.slug,
          kube_namespace: namespace,
          environment_filter: %{container_name!="POD",environment="#{environment.slug}"}
        }
      end
    end
  end
end
