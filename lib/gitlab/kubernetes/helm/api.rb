module Gitlab
  module Kubernetes
    module Helm
      class Api
        def initialize(kubeclient)
          @kubeclient = kubeclient
          @namespace = Gitlab::Kubernetes::Namespace.new(Gitlab::Kubernetes::Helm::NAMESPACE, kubeclient)
        end

        def install(command)
          @namespace.ensure_exists!
          @kubeclient.create_pod(pod_resource(command))
        end

        ##
        # Returns Pod phase
        #
        # https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-phase
        #
        # values: "Pending", "Running", "Succeeded", "Failed", "Unknown"
        #
        def installation_status(pod_name)
          @kubeclient.get_pod(pod_name, @namespace.name).status.phase
        end

        def installation_log(pod_name)
          @kubeclient.get_pod_log(pod_name, @namespace.name).body
        end

        def delete_installation_pod!(pod_name)
          @kubeclient.delete_pod(pod_name, @namespace.name)
        end

        private

        def pod_resource(command)
          Gitlab::Kubernetes::Helm::Pod.new(command, @namespace.name, @kubeclient).generate
        end
      end
    end
  end
end
