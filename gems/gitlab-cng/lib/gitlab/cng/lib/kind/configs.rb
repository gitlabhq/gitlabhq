# frozen_string_literal: true

require "tmpdir"
require "erb"

module Gitlab
  module Cng
    module Kind
      # Kind configuration file templates
      #
      module Configs
        # Temporary ci specific kind configuration file
        #
        # @param [String] docker_hostname
        # @return [String] file path
        def ci_config(docker_hostname)
          config_yml = <<~YML
            apiVersion: kind.x-k8s.io/v1alpha4
            kind: Cluster
            networking:
              apiServerAddress: "0.0.0.0"
            nodes:
              - role: control-plane
                kubeadmConfigPatches:
                  - |
                    kind: InitConfiguration
                    nodeRegistration:
                      kubeletExtraArgs:
                        node-labels: "ingress-ready=true"
                  - |
                    kind: ClusterConfiguration
                    apiServer:
                      certSANs:
                        - "#{docker_hostname}"
                extraPortMappings:
                    # containerPort below must match the values file:
                    #   nginx-ingress.controller.service.nodePorts.http
                  - containerPort: 32080
                    hostPort: 80
                    listenAddress: "0.0.0.0"
                    # containerPort below must match the values file:
                    #   nginx-ingress.controller.service.nodePorts.gitlab-shell
                  - containerPort: 32022
                    hostPort: 22
                    listenAddress: "0.0.0.0"
          YML

          tmp_config_file(config_yml)
        end

        # Temporary kind configuration file
        #
        # @param [String, nil] docker_hostname
        # @return [String] file path
        def default_config(docker_hostname)
          template = ERB.new(<<~YML, trim_mode: "-")
            kind: Cluster
            apiVersion: kind.x-k8s.io/v1alpha4
            nodes:
            - role: control-plane
              kubeadmConfigPatches:
                - |
                  kind: InitConfiguration
                  nodeRegistration:
                    kubeletExtraArgs:
                      node-labels: "ingress-ready=true"
            <% if docker_hostname -%>
                - |
                  kind: ClusterConfiguration
                  apiServer:
                    certSANs:
                      - "<%= docker_hostname %>"
            <% end -%>
              extraPortMappings:
                # containerPort below must match the values file:
                #   nginx-ingress.controller.service.nodePorts.http
              - containerPort: 32080
                hostPort: 32080
                listenAddress: "0.0.0.0"
                # containerPort below must match the values file:
                #   nginx-ingress.controller.service.nodePorts.ssh
              - containerPort: 32022
                hostPort: 32022
                listenAddress: "0.0.0.0"
          YML

          tmp_config_file(template.result(binding))
        end

        # Create temporary kind config file
        #
        # @param [String] config_yml
        # @return [String]
        def tmp_config_file(config_yml)
          File.join(Dir.tmpdir, "kind-config.yml").tap do |path|
            File.write(path, config_yml)
          end
        end
      end
    end
  end
end
