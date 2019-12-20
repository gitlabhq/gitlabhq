# frozen_string_literal: true

require 'securerandom'

module QA
  module Resource
    class KubernetesCluster < Base
      attr_writer :project, :cluster,
        :install_helm_tiller, :install_ingress, :install_prometheus, :install_runner, :domain

      attribute :ingress_ip do
        Page::Project::Operations::Kubernetes::Show.perform(&:ingress_ip)
      end

      def fabricate!
        @project.visit!

        Page::Project::Menu.perform(
          &:go_to_operations_kubernetes)

        Page::Project::Operations::Kubernetes::Index.perform(
          &:add_kubernetes_cluster)

        Page::Project::Operations::Kubernetes::Add.perform(
          &:add_existing_cluster)

        Page::Project::Operations::Kubernetes::AddExisting.perform do |cluster_page|
          cluster_page.set_cluster_name(@cluster.cluster_name)
          cluster_page.set_api_url(@cluster.api_url)
          cluster_page.set_ca_certificate(@cluster.ca_certificate)
          cluster_page.set_token(@cluster.token)
          cluster_page.uncheck_rbac! unless @cluster.rbac
          cluster_page.add_cluster!
        end

        if @install_helm_tiller
          Page::Project::Operations::Kubernetes::Show.perform do |show|
            # We must wait a few seconds for permissions to be set up correctly for new cluster
            sleep 10

            # Helm must be installed before everything else
            show.install!(:helm)
            show.await_installed(:helm)

            show.install!(:ingress) if @install_ingress
            show.install!(:prometheus) if @install_prometheus
            show.install!(:runner) if @install_runner

            show.await_installed(:ingress) if @install_ingress
            show.await_installed(:prometheus) if @install_prometheus
            show.await_installed(:runner) if @install_runner

            if @install_ingress
              populate(:ingress_ip)
              show.set_domain("#{ingress_ip}.nip.io")
              show.save_domain
            end
          end
        end
      end
    end
  end
end
