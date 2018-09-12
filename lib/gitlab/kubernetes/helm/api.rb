module Gitlab
  module Kubernetes
    module Helm
      class Api
        def initialize(kubeclient)
          @kubeclient = kubeclient
          @namespace = Gitlab::Kubernetes::Namespace.new(Gitlab::Kubernetes::Helm::NAMESPACE, kubeclient)
        end

        def install(command)
          namespace.ensure_exists!

          create_service_account(command)
          create_cluster_role_binding(command)
          create_config_map(command)

          kubeclient.create_pod(command.pod_resource)
        end

        ##
        # Returns Pod phase
        #
        # https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-phase
        #
        # values: "Pending", "Running", "Succeeded", "Failed", "Unknown"
        #
        def status(pod_name)
          kubeclient.get_pod(pod_name, namespace.name).status.phase
        end

        def log(pod_name)
          kubeclient.get_pod_log(pod_name, namespace.name).body
        end

        def delete_pod!(pod_name)
          kubeclient.delete_pod(pod_name, namespace.name)
        end

        private

        attr_reader :kubeclient, :namespace

        def create_config_map(command)
          command.config_map_resource.tap do |config_map_resource|
            break unless config_map_resource

            if service_account_exists?(config_map_resource)
              kubeclient.update_config_map(config_map_resource)
            else
              kubeclient.create_config_map(config_map_resource)
            end
          end
        end

        def create_service_account(command)
          command.service_account_resource.tap do |service_account_resource|
            break unless service_account_resource

            if service_account_exists?(service_account_resource)
              kubeclient.update_service_account(service_account_resource)
            else
              kubeclient.create_service_account(service_account_resource)
            end
          end
        end

        def create_cluster_role_binding(command)
          command.cluster_role_binding_resource.tap do |cluster_role_binding_resource|
            break unless cluster_role_binding_resource

            if cluster_role_binding_exists?(cluster_role_binding_resource)
              kubeclient.update_cluster_role_binding(cluster_role_binding_resource)
            else
              kubeclient.create_cluster_role_binding(cluster_role_binding_resource)
            end
          end
        end

        def service_account_exists?(resource)
          resource_exists? do
            kubeclient.get_service_account(resource.metadata.name, resource.metadata.namespace)
          end
        end

        def config_map_exists?(resource)
          resource_exists? do
            kubeclient.get_config_map(resource.metadata.name, resource.metadata.namespace)
          end
        end

        def cluster_role_binding_exists?(resource)
          resource_exists? do
            kubeclient.get_cluster_role_binding(resource.metadata.name)
          end
        end

        def resource_exists?
          yield
        rescue ::Kubeclient::HttpError => e
          raise e unless e.error_code == 404

          false
        end
      end
    end
  end
end
