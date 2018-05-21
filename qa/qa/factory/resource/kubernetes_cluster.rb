require 'securerandom'

module QA
  module Factory
    module Resource
      class KubernetesCluster < Factory::Base

        attr_writer :project, :cluster_name, :api_url, :ca_certificate, :token, :install_helm_tiller, :install_ingress, :install_prometheus, :install_runner

        def fabricate!
          @project.visit!

          Page::Menu::Side.act { click_operations_kubernetes }

          Page::Project::Operations::Kubernetes::Index.perform do |p|
            p.add_kubernetes_cluster
          end

          Page::Project::Operations::Kubernetes::Add.perform do |p|
            p.add_existing_cluster
          end

          Page::Project::Operations::Kubernetes::AddExisting.perform do |p|
            p.set_cluster_name(@cluster_name)
            p.set_api_url(@api_url)
            p.set_ca_certificate(@ca_certificate)
            p.set_token(@token)
            p.add_cluster!
          end

          if @install_helm_tiller
            Page::Project::Operations::Kubernetes::Show.perform do |p|
              p.install_helm_tiller!
              p.install_ingress! if @install_ingress
              p.install_prometheus! if @install_prometheus
              p.install_runner! if @install_runner
            end
          end
        end
      end
    end
  end
end
