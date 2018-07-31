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
          create_config_map(command) if command.config_map?
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
            kubeclient.create_config_map(config_map_resource)
          end
        end
      end
    end
  end
end
