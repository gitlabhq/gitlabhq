module EE
  module Gitlab
    module Kubernetes
      module Helm
        module Api
          def get_config_map(command)
            namespace.ensure_exists!

            return unless command.config_map?

            kubeclient.get_config_map(command.config_map_name, namespace.name)
          end

          def update(command)
            namespace.ensure_exists!
            update_config_map(command) if command.config_map?
            kubeclient.create_pod(command.pod_resource)
          end

          private

          def update_config_map(command)
            command.config_map_resource.tap do |config_map_resource|
              kubeclient.update_config_map(config_map_resource)
            end
          end
        end
      end
    end
  end
end
