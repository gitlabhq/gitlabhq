module Clusters
  module Applications
    class Jupyter < ActiveRecord::Base
      VERSION = '0.0.1'.freeze

      self.table_name = 'clusters_applications_jupyters'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Clusters::Concerns::ApplicationData

      default_value_for :version, VERSION

      def chart
        "#{name}/jupyterhub"
      end

      def repository
        'https://jupyterhub.github.io/helm-chart/'
      end

      def values
        content_values.to_yaml
      end

      def install_command
        Gitlab::Kubernetes::Helm::InstallCommand.new(
          name,
          chart: chart,
          values: values,
          repository: repository
        )
      end

      private

      def specification
        {
          "ingress" => { "hosts" => [hostname] },
          "hub" => { "cookieSecret" => SecureRandom.hex(32) },
          "proxy" => { "secretToken" => SecureRandom.hex(32) }
        }
      end

      def content_values
        YAML.load_file(chart_values_file).deep_merge!(specification)
      end
    end
  end
end
