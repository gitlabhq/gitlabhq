# frozen_string_literal: true

require "socket"

module QA
  module Service
    module DockerRun
      class Smocker < Base
        DEFAULT_SERVER_PORT = 8080
        DEFAULT_CONFIG_PORT = 8081

        private_class_method :new

        class << self
          # Create new instance of smocker container with random name and ports
          #
          # @return [QA::Service::DockerRun::Smocker]
          def create
            container = new
            container.register!
            container.wait_for_running

            container
          rescue StandardError => e
            Runtime::Logger.error("Failed to start smocker container, logs:\n#{container.logs}")
            raise e
          end

          # @param wait [Integer] seconds to wait for server
          # @yieldparam [SmockerApi] the api object ready for interaction
          def init(wait: 10)
            if @container.nil?
              @container = create

              @api = Vendor::Smocker::SmockerApi.new(
                host: @container.host_name,
                public_port: @container.public_port,
                admin_port: @container.admin_port
              )
              @api.wait_for_ready(wait: wait)
            end

            yield @api
          end

          def teardown!
            @container&.remove!
            @container = nil
            @api = nil
          end
        end

        def initialize
          @image = 'thiht/smocker:0.18.5'
          @name = "smocker-service-#{SecureRandom.hex(6)}"

          super()
        end

        # Wait for container to be running
        #
        # @return [void]
        def wait_for_running
          Support::Waiter.wait_until(max_duration: 10, reload_page: false) do
            running?
          end
        end

        # Start smocker container
        #
        # @return [void]
        def register!
          return if running?

          command = %W[docker run -d --network #{network} --name #{name}]
          # when host network is used, published ports are discarded and service in container runs as if on host
          # make sure random open ports are fetched and configured for smocker server
          command.push("-e", "SMOCKER_MOCK_SERVER_LISTEN_PORT=#{host_network? ? server_port : DEFAULT_SERVER_PORT}")
          command.push("-e", "SMOCKER_CONFIG_LISTEN_PORT=#{host_network? ? config_port : DEFAULT_CONFIG_PORT}")
          command.push("--publish-all") unless host_network?
          command.push(image)

          shell command.join(" ")
        end

        # Server port
        #
        # When running in contained docker network, return internal port because service is accessed using hostname:port
        #
        # @return [Integer]
        def public_port
          @public_port ||= if host_network?
                             server_port
                           elsif docker_network?
                             DEFAULT_SERVER_PORT
                           else
                             fetch_published_port(DEFAULT_SERVER_PORT)
                           end
        end

        # Admin port
        #
        # When running in contained docker network, return internal port because service is accessed using hostname:port
        #
        # @return [Integer]
        def admin_port
          @admin_port ||= if host_network?
                            config_port
                          elsif docker_network?
                            DEFAULT_CONFIG_PORT
                          else
                            fetch_published_port(DEFAULT_CONFIG_PORT)
                          end
        end

        private

        attr_reader :name, :image

        # Random open port for server
        #
        # @return [Integer]
        def server_port
          @server_port ||= random_port
        end

        # Random open port for server configuration
        #
        # @return [Integer]
        def config_port
          @config_port ||= random_port
        end

        # Host network used?
        #
        # @return [Boolea]
        def host_network?
          network == "host"
        end

        # Running within custom docker network
        #
        # @return [Boolean]
        def docker_network?
          host_name == "#{name}.#{network}"
        end

        # Fetch published container port
        #
        # @param [Integer] container_port
        # @return [Integer]
        def fetch_published_port(container_port)
          port = published_ports.split("\n").find { |line| line.start_with?(container_port.to_s) }.split(':').last
          raise("Could not find published #{container_port} port for container #{name}") unless port

          port.to_i
        end

        # Published ports for smocker container
        #
        # @return [String]
        def published_ports
          @published_ports ||= shell("docker port #{name}").presence || raise(
            "Unable to fetch published ports for smocker container #{name}"
          )
        end

        # Random unassigned port
        #
        # @return [Integer]
        def random_port
          server = TCPServer.new('127.0.0.1', 0)
          port = server.addr[1]
          server.close
          port
        end
      end
    end
  end
end
