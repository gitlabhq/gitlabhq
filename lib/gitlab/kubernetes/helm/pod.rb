module Gitlab
  module Kubernetes
    module Helm
      class Pod
        def initialize(command, namespace_name)
          @command = command
          @namespace_name = namespace_name
        end

        def generate
          spec = { containers: [container_specification], restartPolicy: 'Never' }

          if command.config_map?
            spec[:volumes] = volumes_specification
            spec[:containers][0][:volumeMounts] = volume_mounts_specification
          end

          ::Kubeclient::Resource.new(metadata: metadata, spec: spec)
        end

        private

        attr_reader :command, :namespace_name, :kubeclient, :config_map

        def container_specification
          {
            name: 'helm',
            image: 'alpine:3.6',
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
          {
            HELM_VERSION: Gitlab::Kubernetes::Helm::HELM_VERSION,
            TILLER_NAMESPACE: namespace_name,
            COMMAND_SCRIPT: command.generate_script
          }.map { |key, value| { name: key, value: value } }
        end

        def volumes_specification
          [
            {
              name: 'configuration-volume',
              configMap: {
                name: "values-content-configuration-#{command.name}",
                items: [{ key: 'values', path: 'values.yaml' }]
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
