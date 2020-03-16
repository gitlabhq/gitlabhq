# frozen_string_literal: true

module Gitlab
  module Prometheus
    module QueryVariables
      def self.call(environment)
        {
          ci_environment_slug: environment.slug,
          kube_namespace: environment.deployment_namespace || '',
          environment_filter: %{container_name!="POD",environment="#{environment.slug}"},
          ci_project_name: environment.project.name,
          ci_project_namespace: environment.project.namespace.name,
          ci_project_path: environment.project.full_path,
          ci_environment_name: environment.name
        }
      end
    end
  end
end
