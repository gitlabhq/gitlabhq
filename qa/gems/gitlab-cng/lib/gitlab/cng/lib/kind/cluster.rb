# frozen_string_literal: true

require "tmpdir"
require "erb"

module Gitlab
  module Cng
    module Kind
      # Class responsible for creating kind cluster
      #
      class Cluster
        include Helpers::Output
        include Helpers::Shell
        extend Helpers::Output
        extend Helpers::Shell

        HTTP_PORT = 32080
        SSH_PORT = 32022

        def initialize(ci:, name:, host_http_port:, host_ssh_port:, docker_hostname: nil)
          @ci = ci
          @name = name
          @host_http_port = host_http_port
          @host_ssh_port = host_ssh_port
          @docker_hostname = ci ? docker_hostname || "docker" : docker_hostname
        end

        # Destroy kind cluster
        #
        # @param [String] name
        # @return [void]
        def self.destroy(name)
          log("Destroying cluster '#{name}'", :info, bright: true)
          return log("Cluster not found, skipping!", :warn) unless execute_shell(%w[kind get clusters]).include?(name)

          Helpers::Spinner.spin("destroying cluster") do
            puts execute_shell(%W[kind delete cluster --name #{name}])
          end
        end

        def create
          log("Creating cluster '#{name}'", :info, bright: true)
          return log("  cluster '#{name}' already exists, skipping!", :warn) if cluster_exists?

          create_cluster
          update_server_url
          log("Cluster '#{name}' created", :success)
        rescue Helpers::Shell::CommandFailure
          # Exit cleanly without stacktrace if shell command fails
          exit(1)
        end

        private

        attr_reader :ci, :name, :docker_hostname, :host_http_port, :host_ssh_port

        # Create kind cluster
        #
        # @return [void]
        def create_cluster
          Helpers::Spinner.spin("performing cluster creation") do
            puts execute_shell([
              "kind",
              "create",
              "cluster",
              "--name", name,
              "--wait", "30s",
              "--config", ci ? ci_config : default_config
            ])
          end
        end

        # Update server url in kubeconfig for kubectl to work correctly with remote docker
        #
        # @return [void]
        def update_server_url
          return unless docker_hostname

          Helpers::Spinner.spin("updating kind cluster server url") do
            cluster_name = "kind-#{name}"
            server = execute_shell([
              "kubectl", "config", "view",
              "-o", "jsonpath={.clusters[?(@.name == \"#{cluster_name}\")].cluster.server}"
            ])
            uri = URI.parse(server).tap { |uri| uri.host = docker_hostname }
            execute_shell(%W[kubectl config set-cluster #{cluster_name} --server=#{uri}])
          end
        end

        # Check if cluster exists
        #
        # @return [Boolean]
        def cluster_exists?
          execute_shell(%w[kind get clusters]).include?(name)
        end

        # Create temporary kind config file
        #
        # @param [String] config_yml
        # @return [String]
        def tmp_config_file(config_yml)
          File.join(Helpers::Utils.tmp_dir, "kind-config.yml").tap do |path|
            File.write(path, config_yml)
          end
        end

        # Temporary ci specific kind configuration file
        #
        # @return [String] file path
        def ci_config
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
                  - containerPort: #{HTTP_PORT}
                    hostPort: #{host_http_port}
                    listenAddress: "0.0.0.0"
                  - containerPort: #{SSH_PORT}
                    hostPort: #{host_ssh_port}
                    listenAddress: "0.0.0.0"
          YML

          tmp_config_file(config_yml)
        end

        # Temporary kind configuration file
        #
        # @return [String] file path
        def default_config
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
                - containerPort: #{HTTP_PORT}
                  hostPort: #{host_http_port}
                  listenAddress: "0.0.0.0"
                - containerPort: #{SSH_PORT}
                  hostPort: #{host_ssh_port}
                  listenAddress: "0.0.0.0"
          YML

          tmp_config_file(template.result(binding))
        end
      end
    end
  end
end
