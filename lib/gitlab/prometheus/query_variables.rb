# frozen_string_literal: true

module Gitlab
  module Prometheus
    module QueryVariables
      def self.call(environment)
        deployment_platform = environment.deployment_platform
        namespace = deployment_platform&.kubernetes_namespace_for(environment.project) || ''

        {
          ci_environment_slug: environment.slug,
          kube_namespace: namespace,
          environment_filter: %{container_name!="POD",environment="#{environment.slug}"}
        }
      end
    end
  end
end
