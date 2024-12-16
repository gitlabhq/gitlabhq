# frozen_string_literal: true

module Gitlab
  module Cng
    module Kubectl
      # Wrapper around kubectl client
      #
      class Client
        include Helpers::Shell
        include Helpers::Output

        # Error raised by kubectl client class
        Error = Class.new(StandardError)

        def initialize(namespace)
          @namespace = namespace
        end

        # Create namespace
        #
        # @return [String] command output
        def create_namespace
          execute_shell(["kubectl", "create", "namespace", namespace])
        rescue Helpers::Shell::CommandFailure => e
          raise(Error, e.message)
        end

        # Create kubernetes resource
        #
        # @param [Resources::Base] resource
        # @return [String] command output
        def create_resource(resource)
          run_in_namespace("apply", args: ["-f", "-"], stdin_data: resource.json)
        end

        # Remove kubernetes resource
        #
        # @param [String] resource_type
        # @param [String] resource_name
        # @param [Boolean] ignore_not_found
        # @return [String] command output
        def delete_resource(resource_type, resource_name, ignore_not_found: true)
          run_in_namespace("delete", resource_type, resource_name, args: [
            "--ignore-not-found=#{ignore_not_found}", "--wait"
          ])
        end

        # Execute command in a pod
        #
        # @param [String] pod full or part of pod name
        # @param [Array] command
        # @param [String] container
        # @return [String]
        def execute(pod_name, command, container: nil)
          args = ["--", *command]
          args.unshift("-c", container) if container

          run_in_namespace("exec", get_pod_name(pod_name), args: args)
        end

        # Get pod logs
        #
        # @param [Array<String>] pods
        # @param [String] since
        # @param [String] containers
        # @return [Hash<String, String>]
        def pod_logs(pods, since: "1h", containers: "default")
          pod_data = JSON.parse(all_pods)["items"]
            .select { |pod| pods.empty? || pods.any? { |p| pod.dig("metadata", "name").include?(p) } }
            .each_with_object({}) { |pod, hash| hash[pod.dig("metadata", "name")] = pod.slice("metadata", "spec") }

          if pod_data.empty?
            raise Error, "No pods matched: #{pods.join(', ')}" unless pods.empty?

            raise Error, "No pods found in namespace '#{namespace}'"
          end

          log("Fetching logs for pods '#{pod_data.keys.join(', ')}'", :info)
          pod_data.to_h do |pod_name, data|
            default_container = data.dig("spec", "containers").first["name"]
            [
              pod_name,
              run_in_namespace("logs", "pod/#{pod_name}", args: [
                "--since=#{since}",
                "--prefix=true",
                containers == "default" ? "--container=#{default_container}" : "--all-containers=true"
              ])
            ]
          end
        end

        # Get events
        #
        # @param [Boolean] json_format
        # @return [String]
        def events(json_format: false)
          args = ["--sort-by=lastTimestamp"]
          args << "--output=json" if json_format
          run_in_namespace("get", "events", args: args)
        end

        # Patch kubernetes resource
        #
        # @param [String] resource_type
        # @param [String] resource_name
        # @param [String] patch_data
        # @param [String] patch_type default: 'merge'
        # @return [String] command output
        def patch(resource_type, resource_name, patch_data, patch_type: 'merge')
          run_in_namespace("patch", resource_type, resource_name, args: [
            "--type=#{patch_type}",
            "-p", patch_data
          ])
        end

        private

        attr_reader :namespace

        # Get all pods in namespace
        #
        # @param [String] output --output type
        # @return [String]
        def all_pods(output: "json")
          run_in_namespace("get", "pods", args: ["--output", output])
        end

        # Get full pod name
        #
        # @param [String] name
        # @return [String]
        def get_pod_name(name)
          pod_name = all_pods(output: "jsonpath={.items[*].metadata.name}")
            .split(" ")
            .find { |pod_name| pod_name.include?(name) }
          raise Error, "Pod '#{name}' not found" unless pod_name

          pod_name
        end

        # Run kubectl command in namespace
        #
        # @param [Array] *action
        # @param [Array] args
        # @param [String] stdin_data
        # @return [String]
        def run_in_namespace(*action, args:, stdin_data: nil)
          execute_shell(["kubectl", *action, "-n", namespace, *args], stdin_data: stdin_data)
        rescue Helpers::Shell::CommandFailure => e
          raise(Error, e.message)
        end
      end
    end
  end
end
