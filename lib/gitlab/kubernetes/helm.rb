module Gitlab
  module Kubernetes
    class Helm
      HELM_VERSION = '2.7.0'.freeze
      NAMESPACE = 'gitlab-managed-apps'.freeze
      COMMAND_SCRIPT = <<-EOS.freeze
        set -eo pipefail
        apk add -U ca-certificates openssl >/dev/null
        wget -q -O - https://kubernetes-helm.storage.googleapis.com/helm-v${HELM_VERSION}-linux-amd64.tar.gz | tar zxC /tmp >/dev/null
        mv /tmp/linux-amd64/helm /usr/bin/
        helm init ${HELM_INIT_OPTS} >/dev/null
        [[ -z "${HELM_COMMAND+x}" ]] || helm ${HELM_COMMAND} >/dev/null
      EOS

      def initialize(kubeclient)
        @kubeclient = kubeclient
      end

      def init!
        install(OpenStruct.new(name: 'helm'))
      end

      def install(app)
        create_namespace! unless has_namespace?
        @kubeclient.create_pod(pod_resource(app))
      end

      ##
      # Returns Pod phase
      #
      # https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-phase
      #
      # values: "Pending", "Running", "Succeeded", "Failed", "Unknown"
      #
      def installation_status(app)
        @kubeclient.get_pod(pod_name(app), NAMESPACE).status.phase
      end

      def installation_log(app)
        @kubeclient.get_pod_log(pod_name(app), NAMESPACE).body
      end

      def delete_installation_pod!(app)
        @kubeclient.delete_pod(pod_name(app), NAMESPACE)
      end

      private

      def pod_name(app)
        "install-#{app.name}"
      end

      def pod_resource(app)
        labels = { 'gitlab.org/action': 'install', 'gitlab.org/application': app.name }
        metadata = { name: pod_name(app), namespace: NAMESPACE, labels: labels }
        container = {
          name: 'helm',
          image: 'alpine:3.6',
          env: generate_pod_env(app),
          command: %w(/bin/sh),
          args: %w(-c $(COMMAND_SCRIPT))
        }
        spec = { containers: [container], restartPolicy: 'Never' }

        ::Kubeclient::Resource.new(metadata: metadata, spec: spec)
      end

      def generate_pod_env(app)
        env = {
          HELM_VERSION: HELM_VERSION,
          TILLER_NAMESPACE: NAMESPACE,
          COMMAND_SCRIPT: COMMAND_SCRIPT
        }

        if app.name != 'helm'
          env[:HELM_INIT_OPTS] = '--client-only'
          env[:HELM_COMMAND] = helm_install_comand(app)
        end

        env.map { |key, value| { name: key, value: value } }
      end

      def helm_install_comand(app)
        "install #{app.chart} --name #{app.name} --namespace #{NAMESPACE}"
      end

      def has_namespace?
        return @has_namespace if defined?(@has_namespace)

        begin
          @kubeclient.get_namespace(NAMESPACE)
          @has_namespace = true
        rescue KubeException => ke
          raise ke unless ke.error_code == 404
          false
        end
      end

      def create_namespace!
        namespace_resource = ::Kubeclient::Resource.new
        namespace_resource.metadata = {}
        namespace_resource.metadata.name = NAMESPACE

        @kubeclient.create_namespace(namespace_resource)
      end
    end
  end
end
