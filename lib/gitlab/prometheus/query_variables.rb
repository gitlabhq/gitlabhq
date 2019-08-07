# frozen_string_literal: true

module Gitlab
  module Prometheus
    module QueryVariables
      def self.call(environment)
        {
          ci_environment_slug: environment.slug,
          kube_namespace: environment.deployment_namespace || '',
          environment_filter: %{container_name!="POD",environment="#{environment.slug}"}
        }
      end
    end
  end
end
