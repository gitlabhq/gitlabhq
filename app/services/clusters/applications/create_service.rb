# frozen_string_literal: true

module Clusters
  module Applications
    class CreateService < Clusters::Applications::BaseService
      private

      def worker_class(application)
        application.updateable? ? ClusterUpgradeAppWorker : ClusterInstallAppWorker
      end

      def builders
        {
          "helm" => -> (cluster) { cluster.application_helm || cluster.build_application_helm },
          "ingress" => -> (cluster) { cluster.application_ingress || cluster.build_application_ingress },
          "cert_manager" => -> (cluster) { cluster.application_cert_manager || cluster.build_application_cert_manager },
          "runner" => -> (cluster) { cluster.application_runner || cluster.build_application_runner }
        }.tap do |hash|
          hash.merge!(project_builders) if cluster.project_type?
        end
      end

      # These applications will need extra configuration to enable them to work
      # with groups of projects
      def project_builders
        {
          "prometheus" => -> (cluster) { cluster.application_prometheus || cluster.build_application_prometheus },
          "jupyter" => -> (cluster) { cluster.application_jupyter || cluster.build_application_jupyter },
          "knative" => -> (cluster) { cluster.application_knative || cluster.build_application_knative }
        }
      end
    end
  end
end
