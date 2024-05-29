# frozen_string_literal: true

require "uri"

require_relative "configs"

module Gitlab
  module Cng
    module Kind
      # Class responsible for creating kind cluster
      #
      class Cluster
        include Helpers::Output
        include Helpers::Shell
        include Configs

        def initialize(ci:, name:, docker_hostname: nil)
          @ci = ci
          @name = name
          @docker_hostname = ci ? docker_hostname || "docker" : docker_hostname
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

        attr_reader :ci, :name, :docker_hostname

        # Check if cluster exists
        #
        # @return [Boolean]
        def cluster_exists?
          execute_shell(%w[kind get clusters]).include?(name)
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
              "--config", ci ? ci_config(docker_hostname) : default_config(docker_hostname)
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
      end
    end
  end
end
