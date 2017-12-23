module Gitlab
  module Kubernetes
    module Helm
      class Pod
        def initialize(command, namespace_name, kubeclient)
          @command = command
          @namespace_name = namespace_name
          @kubeclient = kubeclient
        end

        def generate
          spec = { containers: [container_specification], restartPolicy: 'Never' }
          if command.chart_values_file
            generate_config_map
            spec['volumes'] = volumes_specification
          end
          ::Kubeclient::Resource.new(metadata: metadata, spec: spec)
        end

        private

        attr_reader :command, :namespace_name, :kubeclient

        def container_specification
          container = {
            name: 'helm',
            image: 'alpine:3.6',
            env: generate_pod_env(command),
            command: %w(/bin/sh),
            args: %w(-c $(COMMAND_SCRIPT))
          }
          container[:volumeMounts] = volume_mounts_specification if command.chart_values_file
          container
        end

        def labels
          { 'gitlab.org/action': 'install', 'gitlab.org/application': command.name }
        end

        def metadata
          { name: command.pod_name, namespace: namespace_name, labels: labels }
        end

        def volume_mounts_specification
          [{ name: 'config-volume', mountPath: '/etc/config' }]
        end

        def volumes_specification
          [{ name: 'config-volume', configMap: { name: 'values-config' } }]
        end

        def generate_pod_env(command)
          {
            HELM_VERSION: Gitlab::Kubernetes::Helm::HELM_VERSION,
            TILLER_NAMESPACE: namespace_name,
            COMMAND_SCRIPT: command.generate_script(namespace_name)
          }.map { |key, value| { name: key, value: value } }
        end

        def generate_config_map
          resource = ::Kubeclient::Resource.new
          resource.metadata = { name: 'values-config', namespace: namespace_name }
          resource.data = YAML.load_file(command.chart_values_file)
          kubeclient.create_config_map(resource)
        end
      end
    end
  end
end
