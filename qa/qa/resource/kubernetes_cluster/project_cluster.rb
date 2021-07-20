# frozen_string_literal: true

module QA
  module Resource
    module KubernetesCluster
      # TODO: This resource is currently broken, since one-click apps have been removed.
      #       See https://gitlab.com/gitlab-org/gitlab/-/issues/333818
      class ProjectCluster < Base
        attr_writer :cluster,
                    :install_ingress, :install_prometheus, :install_runner, :domain

        attribute :project do
          Resource::Project.fabricate!
        end

        def ingress_ip
          @ingress_ip ||= @cluster.fetch_external_ip_for_ingress
        end

        def fabricate!
          project.visit!

          Page::Project::Menu.perform(
            &:go_to_infrastructure_kubernetes)

          Page::Project::Infrastructure::Kubernetes::Index.perform(
            &:add_kubernetes_cluster)

          Page::Project::Infrastructure::Kubernetes::Add.perform(
            &:add_existing_cluster)

          Page::Project::Infrastructure::Kubernetes::AddExisting.perform do |cluster_page|
            cluster_page.set_cluster_name(@cluster.cluster_name)
            cluster_page.set_api_url(@cluster.api_url)
            cluster_page.set_ca_certificate(@cluster.ca_certificate)
            cluster_page.set_token(@cluster.token)
            cluster_page.uncheck_rbac! unless @cluster.rbac
            cluster_page.add_cluster!
          end

          Page::Project::Infrastructure::Kubernetes::Show.perform do |show|
            # We must wait a few seconds for permissions to be set up correctly for new cluster
            sleep 25

            if @install_ingress
              populate(:ingress_ip)

              show.open_details
              show.set_domain("#{ingress_ip}.nip.io")
              show.save_domain
            end
          end
        end
      end
    end
  end
end
