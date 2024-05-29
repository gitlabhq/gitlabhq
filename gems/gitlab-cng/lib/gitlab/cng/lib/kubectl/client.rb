# frozen_string_literal: true

module Gitlab
  module Cng
    module Kubectl
      # Wrapper around kubectl client
      #
      class Client
        include Helpers::Shell

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
        end

        # Create kubernetes resource
        #
        # @param [Resources::Base] resource
        # @return [String] command output
        def create_resource(resource)
          run_in_namespace("apply", args: ["-f", "-"], stdin_data: resource.json)
        end

        # Execute command in a pod
        #
        # @param [String] pod full or part of pod name
        # @param [Array] command
        # @param [String] container
        # @return [String]
        def execute(pod, command, container: nil)
          args = ["--", *command]
          args.unshift("-c", container) if container

          run_in_namespace("exec", get_pod_name(pod), args: args)
        end

        private

        attr_reader :namespace

        # Get full pod name
        #
        # @param [String] name
        # @return [String]
        def get_pod_name(name)
          pod = run_in_namespace("get", "pods", args: ["--output", "jsonpath={.items[*].metadata.name}"])
            .split(" ")
            .find { |pod| pod.include?(name) }
          raise Error, "Pod '#{name}' not found" unless pod

          pod
        end

        # Run kubectl command in namespace
        #
        # @param [Array] *action
        # @param [Array] args
        # @param [String] stdin_data
        # @return [String]
        def run_in_namespace(*action, args:, stdin_data: nil)
          execute_shell(["kubectl", *action, "-n", namespace, *args], stdin_data: stdin_data)
        end
      end
    end
  end
end
