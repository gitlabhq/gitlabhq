# frozen_string_literal: true

require 'socket'

module QA
  module Service
    module DockerRun
      # TODO: There are a lot of methods that reference @name yet it is not part of initializer
      # Refactor all child implementations to remove assumption that @name will exist
      #
      class Base
        include Service::Shellout

        def self.authenticated_registries
          @authenticated_registries ||= {}
        end

        def initialize
          @network = Runtime::Scenario.attributes[:network] || Runtime::Env.docker_network || 'test'
        end

        # Authenticate against a container registry
        # If authentication is successful, will cache registry
        #
        # @param registry [String] registry to authenticate against
        # @param user [String]
        # @param password [String]
        # @param force [Boolean] force authentication if already authenticated
        # @return [Void]
        def login(registry, user:, password:, force: false)
          return if self.class.authenticated_registries[registry] && !force

          shell(
            %(docker login --username "#{user}" --password "#{password}" #{registry}),
            mask_secrets: [password]
          )

          self.class.authenticated_registries[registry] = true
        end

        def logs
          shell "docker logs #{@name}"
        end

        def network
          return @network_cache if @network_cache

          @network_cache = network_exists?(@network) ? @network : 'bridge'
        end

        def inspect_network(name)
          shell("docker network inspect #{name}", fail_on_exception: false, return_exit_status: true)
        end

        def network_exists?(name)
          _, status = inspect_network(name)
          status == 0
        end

        def pull
          Support::Retrier.retry_until(retry_on_exception: true, sleep_interval: 3) do
            shell "docker pull #{@image}"
          end
        end

        # Host name of the container
        #
        # If host or default bridge network is used, container can only be reached using ip address
        #
        # @return [String]
        def host_name
          @host_name ||= if network == "host" || network == "bridge"
                           host_ip
                         else
                           "#{@name}.#{network}"
                         end
        end

        def register!
          raise NotImplementedError
        end

        def remove!
          shell "docker rm -f #{@name}" if running?
        end

        def running?
          shell("docker ps -f name=#{@name}").include?(@name)
        end

        def read_file(file_path)
          shell("docker exec #{@name} /bin/cat #{file_path}")
        end

        def restart
          return "Container #{@name} is not running, cannot restart." unless running?

          shell "docker restart #{@name}"
        end

        def health
          shell("docker inspect --format='{{json .State.Health.Status}}' #{@name}").delete('"')
        end

        # Returns the IP address of the docker host
        #
        # @return [String]
        def host_ip
          docker_host = shell("docker context inspect --format='{{json .Endpoints.docker.Host}}'").delete('"')
          hostname = URI(docker_host).host
          # The docker host could be bound to a Unix socket, in which case as a URI it has no host
          host = hostname.presence || Socket.gethostname
          ip = Addrinfo.tcp(host, nil).ip_address
          ip == '0.0.0.0' ? '127.0.0.1' : ip
        rescue SocketError
          # If the host could not be resolved, fallback on localhost
          '127.0.0.1'
        end

        # Copy files to/from the Docker container and the host
        #
        # @param from the source path to copy files from
        # @param to the destination path to copy files to
        def copy(from:, to:)
          shell("docker cp #{from} #{to}")
        end
      end
    end
  end
end
