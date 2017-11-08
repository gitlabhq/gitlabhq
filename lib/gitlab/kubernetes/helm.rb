module Gitlab
  module Kubernetes
    class Helm
      HELM_VERSION = '2.7.0'.freeze
      NAMESPACE = 'gitlab-managed-apps'.freeze
      INSTALL_DEPS = <<-EOS.freeze
        set -eo pipefail
        apk add -U ca-certificates openssl >/dev/null
        wget -q -O - https://kubernetes-helm.storage.googleapis.com/helm-v${HELM_VERSION}-linux-amd64.tar.gz | tar zxC /tmp >/dev/null
        mv /tmp/linux-amd64/helm /usr/bin/
      EOS

      InstallCommand = Struct.new(:name, :install_helm, :chart) do
        def pod_name
          "install-#{name}"
        end
      end

      def initialize(kubeclient)
        @kubeclient = kubeclient
        @namespace = Namespace.new(NAMESPACE, kubeclient)
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
        labels = { 'gitlab.org/action': 'install', 'gitlab.org/application': command.name }
        metadata = { name: command.pod_name, namespace: @namespace.name, labels: labels }
        container = {
          name: 'helm',
          image: 'alpine:3.6',
          env: generate_pod_env(command),
          command: %w(/bin/sh),
          args: %w(-c $(COMMAND_SCRIPT))
        }
        spec = { containers: [container], restartPolicy: 'Never' }

        ::Kubeclient::Resource.new(metadata: metadata, spec: spec)
      end

      def generate_pod_env(command)
        {
          HELM_VERSION: HELM_VERSION,
          TILLER_NAMESPACE: @namespace.name,
          COMMAND_SCRIPT: generate_script(command)
        }.map { |key, value| { name: key, value: value } }
      end

      def generate_script(command)
        [
            INSTALL_DEPS,
            helm_init_command(command),
            helm_install_command(command)
        ].join("\n")
      end

      def helm_init_command(command)
        if command.install_helm
          'helm init >/dev/null'
        else
          'helm init --client-only >/dev/null'
        end
      end

      def helm_install_command(command)
        return if command.chart.nil?

        "helm install #{command.chart} --name #{command.name} --namespace #{@namespace.name} >/dev/null"
      end
    end
  end
end
