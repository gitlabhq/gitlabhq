module Clusters
  module Applications
    class Prometheus < ActiveRecord::Base
      VERSION = "2.0.0".freeze

      self.table_name = 'clusters_applications_prometheus'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus

      default_value_for :version, VERSION

      def chart
        'stable/prometheus'
      end

      def namespace
        Gitlab::Kubernetes::Helm::NAMESPACE
      end

      def service_name
        'prometheus-prometheus-server'
      end

      def service_port
        80
      end

      def chart_values_file
        "#{Rails.root}/vendor/#{name}/values.yaml"
      end

      def install_command
        Gitlab::Kubernetes::Helm::InstallCommand.new(name, chart: chart, chart_values_file: chart_values_file)
      end
    end
  end
end
