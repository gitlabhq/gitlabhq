require 'securerandom'

module QA
  module Factory
    module Resource
      class KubernetesCluster < Factory::Base
        attr_writer :project, :cluster,
          :install_helm_tiller, :install_ingress, :install_prometheus, :install_runner

        product :ingress_ip do
          Page::Project::Operations::Kubernetes::Show.perform do |page|
            page.ingress_ip
          end
        end

        def fabricate!
          @project.visit!

          Page::Menu::Side.act { click_operations_kubernetes }

          Page::Project::Operations::Kubernetes::Index.perform do |page|
            page.add_kubernetes_cluster
          end

          Page::Project::Operations::Kubernetes::Add.perform do |page|
            page.add_existing_cluster
          end

          Page::Project::Operations::Kubernetes::AddExisting.perform do |page|
            page.set_cluster_name(@cluster.cluster_name)
            page.set_api_url(@cluster.api_url)
            page.set_ca_certificate(@cluster.ca_certificate)
            page.set_token(@cluster.token)
            page.add_cluster!
          end

          if @install_helm_tiller
            Page::Project::Operations::Kubernetes::Show.perform do |page|
              # We must wait a few seconds for permissions to be setup correctly for new cluster
              sleep 10

              # Helm must be installed before everything else
              page.install!(:helm)
              page.await_installed(:helm)

              page.install!(:ingress) if @install_ingress
              page.install!(:prometheus) if @install_prometheus
              page.install!(:runner) if @install_runner

              page.await_installed(:ingress) if @install_ingress
              page.await_installed(:prometheus) if @install_prometheus
              page.await_installed(:runner) if @install_runner
            end
          end
        end
      end
    end
  end
end
