# frozen_string_literal: true

module Clusters
  module Applications
    class UpdateService < Clusters::Applications::BaseService
      private

      def worker_class(application)
        ClusterPatchAppWorker
      end

      def builders
        {
          "helm" => -> (cluster) { cluster.application_helm },
          "ingress" => -> (cluster) { cluster.application_ingress },
          "cert_manager" => -> (cluster) { cluster.application_cert_manager }
        }.tap do |hash|
          hash.merge!(project_builders) if cluster.project_type?
        end
      end

      # These applications will need extra configuration to enable them to work
      # with groups of projects
      def project_builders
        {
          "prometheus" => -> (cluster) { cluster.application_prometheus },
          "runner" => -> (cluster) { cluster.application_runner },
          "jupyter" => -> (cluster) { cluster.application_jupyter },
          "knative" => -> (cluster) { cluster.application_knative }
        }
      end
    end
  end
end
