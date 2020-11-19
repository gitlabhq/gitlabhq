# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module Helm
      class Pod
        def initialize(command, namespace_name, service_account_name: nil)
          @command = command
          @namespace_name = namespace_name
          @service_account_name = service_account_name
        end

        def generate
          spec = { containers: [container_specification], restartPolicy: 'Never' }

          spec[:volumes] = volumes_specification
          spec[:containers][0][:volumeMounts] = volume_mounts_specification
          spec[:serviceAccountName] = service_account_name if service_account_name

          ::Kubeclient::Resource.new(metadata: metadata, spec: spec)
        end

        private

        attr_reader :command, :namespace_name, :service_account_name

        def container_specification
          {
            name: 'helm',
            image: "registry.gitlab.com/gitlab-org/cluster-integration/helm-install-image/releases/#{command.class::HELM_VERSION}-kube-#{Gitlab::Kubernetes::Helm::KUBECTL_VERSION}-alpine-3.12",
            env: generate_pod_env(command),
            command: %w(/bin/sh),
            args: %w(-c $(COMMAND_SCRIPT))
          }
        end

        def labels
          {
            'gitlab.org/action': 'install',
            'gitlab.org/application': command.name
          }
        end

        def metadata
          {
            name: command.pod_name,
            namespace: namespace_name,
            labels: labels
          }
        end

        def generate_pod_env(command)
          command.env.merge(
            HELM_VERSION: command.class::HELM_VERSION,
            COMMAND_SCRIPT: command.generate_script
          ).map { |key, value| { name: key, value: value } }
        end

        def volumes_specification
          [
            {
              name: 'configuration-volume',
              configMap: {
                name: "values-content-configuration-#{command.name}",
                items: command.file_names.map { |name| { key: name, path: name } }
              }
            }
          ]
        end

        def volume_mounts_specification
          [
            {
              name: 'configuration-volume',
              mountPath: "/data/helm/#{command.name}/config"
            }
          ]
        end
      end
    end
  end
end
