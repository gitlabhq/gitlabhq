# frozen_string_literal: true

module Clusters
  module Applications
    class Crossplane < ApplicationRecord
      VERSION = '0.4.1'

      self.table_name = 'clusters_applications_crossplane'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Clusters::Concerns::ApplicationVersion
      include ::Clusters::Concerns::ApplicationData

      default_value_for :version, VERSION

      default_value_for :stack do |crossplane|
        ''
      end

      validates :stack, presence: true

      def chart
        'crossplane/crossplane'
      end

      def repository
        'https://charts.crossplane.io/alpha'
      end

      def install_command
        Gitlab::Kubernetes::Helm::InstallCommand.new(
          name: 'crossplane',
          repository: repository,
          version: VERSION,
          rbac: cluster.platform_kubernetes_rbac?,
          chart: chart,
          files: files
        )
      end

      def values
        crossplane_values.to_yaml
      end

      private

      def crossplane_values
        {
          "clusterStacks" => {
             self.stack => {
               "deploy" => true,
                  "version" => "alpha"
            }
          }
        }
      end
    end
  end
end
