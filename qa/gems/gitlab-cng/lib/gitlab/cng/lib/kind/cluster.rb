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

        CLUSTER_NAME = "gitlab"

        METRICS_CHART_NAME = "metrics-server"
        METRICS_CHART_URL = "https://kubernetes-sigs.github.io/metrics-server/"
        METRICS_CHART_VERSION = "^3.12"

        class << self
          # Destroy kind cluster
          #
          # @param [String] name
          # @return [void]
          def destroy
            log("Destroying cluster '#{CLUSTER_NAME}'", :info, bright: true)

            unless execute_shell(%w[kind get clusters]).include?(CLUSTER_NAME)
              return log("Cluster not found, skipping!", :warn)
            end

            Helpers::Spinner.spin("destroying cluster") do
              puts execute_shell(%W[kind delete cluster --name #{CLUSTER_NAME}])
            end
          end

          # Get configured port mapping
          #
          # @param [Integer] port
          # @return [Integer]
          def host_port_mapping(port)
            yml = YAML.safe_load(File.read(kind_config_file_name))

            yml["nodes"].first["extraPortMappings"].find { |mapping| mapping["hostPort"] == port }["containerPort"]
          end

          # Kind cluster configuration file
          #
          # @return [String]
          def kind_config_file_name
            File.join(Helpers::Utils.config_dir, "kind-config.yml")
          end
        end

        def initialize(ci:, host_http_port:, host_ssh_port:, host_registry_port:, docker_hostname: nil)
          @ci = ci
          @name = CLUSTER_NAME
          @host_http_port = host_http_port
          @host_ssh_port = host_ssh_port
          @host_registry_port = host_registry_port
          @docker_hostname = ci ? docker_hostname || "docker" : docker_hostname
        end

        def create
          log("Creating cluster '#{name}'", :info, bright: true)
          return log("cluster '#{name}' already exists, skipping!", :warn) if cluster_exists?

          create_cluster
          update_server_url
          install_metrics_server
          log("Cluster '#{name}' created", :success)
        rescue Helpers::Shell::CommandFailure
          # Exit cleanly without stacktrace if shell command fails
          exit(1)
        end

        private

        attr_reader :ci, :name, :docker_hostname, :host_http_port, :host_ssh_port, :host_registry_port

        # Helm client instance
        #
        # @return [Helm::Client]
        def helm_client
          @helm_client ||= Helm::Client.new
        end

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

        # Install metrics-server on cluster
        #
        # Avoids "FailedGetResourceMetric" cluster errors and adds support for resource monitoring
        #
        # @return [void]
        def install_metrics_server
          Helpers::Spinner.spin("installing metrics server", raise_on_error: false) do
            helm_client.add_helm_chart(METRICS_CHART_NAME, METRICS_CHART_URL)
            helm_client.upgrade(
              METRICS_CHART_NAME,
              "#{METRICS_CHART_NAME}/#{METRICS_CHART_NAME}",
              namespace: "kube-system",
              timeout: "1m",
              values: { "args" => ["--kubelet-insecure-tls"] }.to_yaml,
              # use atomic to avoid leaving broken state if install fails
              args: ["--atomic", "--version", METRICS_CHART_VERSION]
            )
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

        # Create kind config file and return it's path
        #
        # @param [String] config_yml
        # @return [String]
        def kind_config_file(config_yml)
          self.class.kind_config_file_name.tap { |path| File.write(path, config_yml) }
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
                  - containerPort: #{http_port}
                    hostPort: #{host_http_port}
                    listenAddress: "0.0.0.0"
                  - containerPort: #{ssh_port}
                    hostPort: #{host_ssh_port}
                    listenAddress: "0.0.0.0"
                  - containerPort: #{registry_port}
                    hostPort: #{host_registry_port}
                    listenAddress: "0.0.0.0"
          YML

          kind_config_file(config_yml)
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
                - containerPort: #{http_port}
                  hostPort: #{host_http_port}
                  listenAddress: "0.0.0.0"
                - containerPort: #{ssh_port}
                  hostPort: #{host_ssh_port}
                  listenAddress: "0.0.0.0"
                - containerPort: #{registry_port}
                  hostPort: #{host_registry_port}
                  listenAddress: "0.0.0.0"
          YML

          kind_config_file(template.result(binding))
        end

        # Random http port to expose outside cluster
        #
        # @return [Integer]
        def http_port
          @http_port ||= rand(30000..31000)
        end

        # Set container registry port to expose outside cluster
        #
        # @return [Integer]
        def registry_port
          @registry_port ||= 32495
        end

        # Random ssh port to expose outside cluster
        #
        # @return [Integer]
        def ssh_port
          @ssh_port ||= rand(31001..32000)
        end
      end
    end
  end
end
