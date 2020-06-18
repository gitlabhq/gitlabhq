# frozen_string_literal: true

module Gitlab
  module Prometheus
    module QueryVariables
      # start_time and end_time should be Time objects.
      def self.call(environment, start_time: nil, end_time: nil)
        {
          __range: range(start_time, end_time),
          ci_environment_slug: environment.slug,
          kube_namespace: environment.deployment_namespace || '',
          environment_filter: %{container_name!="POD",environment="#{environment.slug}"},
          ci_project_name: environment.project.name,
          ci_project_namespace: environment.project.namespace.name,
          ci_project_path: environment.project.full_path,
          ci_environment_name: environment.name
        }
      end

      private

      def self.range(start_time, end_time)
        if start_time && end_time
          range_seconds = (end_time - start_time).to_i
          "#{range_seconds}s"
        end
      end
      private_class_method :range
    end
  end
end
