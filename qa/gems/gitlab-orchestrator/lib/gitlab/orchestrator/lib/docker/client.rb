# frozen_string_literal: true

module Gitlab
  module Orchestrator
    module Docker
      # Docker client error
      #
      Error = Class.new(StandardError)

      # Docker client for managing containers
      #
      class Client
        include Helpers::Shell
        include Helpers::Output

        # Check if Docker container exists
        #
        # @param [String] name
        # @return [Boolean]
        def container_exists?(name)
          cmd = ["docker", "ps", "-a", "-q", "-f", "name=^/#{name}$"]
          !execute_shell(cmd).strip.empty?
        rescue StandardError => e
          raise Error, "Failed to check if container exists: #{e.message}"
        end

        # Create Docker volume
        #
        # @param [String] name
        # @return [String]
        def create_volume(name)
          cmd = ["docker", "volume", "create", name]
          execute_shell(cmd)
        rescue StandardError => e
          raise Error, "Failed to create volume: #{e.message}"
        end

        # Pull Docker image with live output
        #
        # @param [String] image
        # @return [void]
        def pull_image(image)
          cmd = ["docker", "pull", image]
          execute_shell(cmd, live_output: true)

        rescue StandardError => e
          raise Error, "Failed to pull Docker image: #{e.message}"
        end

        # Run Docker container
        #
        # @param [String] name
        # @param [String] image
        # @param [Hash] environment
        # @param [Hash] ports
        # @param [Hash] volumes
        # @param [String] restart
        # @param [Array<String>] additional_options
        # @return [String]
        def run_container(
          name:, image:, environment: {}, ports: {}, volumes: {}, restart: "always",
          additional_options: [])
          cmd = ["docker", "run", "-d", "--name", name]

          environment&.each do |key, value|
            cmd.push("-e", "#{key}=#{value}")
          end

          ports&.each_key do |port|
            cmd.push("-p", port)
          end

          volumes&.each_key do |volume|
            cmd.push("-v", volume)
          end

          cmd.push("--restart", restart)
          cmd.push(*additional_options) if additional_options.any?
          cmd.push(image)

          formatted_cmd = cmd.map do |part|
            part.include?(' ') ? "\"#{part}\"" : part
          end.join(' ')

          log("Running container with command: #{formatted_cmd}", :debug)
          execute_shell(cmd)
        rescue StandardError => e
          raise Error, "Failed to run container: #{e.message}"
        end

        # Execute command in Docker container
        #
        # @param [String] name
        # @param [Array<String>] command
        # @return [String]
        def exec(name, command)
          cmd = ["docker", "exec", name, *command]
          execute_shell(cmd)
        rescue StandardError => e
          raise Error, "Failed to execute command in container: #{e.message}"
        end
      end
    end
  end
end
