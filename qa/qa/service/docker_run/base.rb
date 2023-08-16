# frozen_string_literal: true

require 'socket'

module QA
  module Service
    module DockerRun
      class Base
        include Service::Shellout

        def self.authenticated_registries
          @authenticated_registries ||= {}
        end

        def initialize
          @network = gdk_network || Runtime::Scenario.attributes[:network] || 'test'
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
          network_exists?(@network) ? @network : 'bridge'
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

        def host_name
          "#{@name}.#{network}"
        end

        def register!
          raise NotImplementedError
        end

        def remove!
          shell "docker rm -f #{@name}" if running?
        end

        def running?
          `docker ps -f name=#{@name}`.include?(@name)
        end

        def read_file(file_path)
          `docker exec #{@name} /bin/cat #{file_path}`
        end

        def restart
          return "Container #{@name} is not running, cannot restart." unless running?

          shell "docker restart #{@name}"
        end

        def health
          shell("docker inspect --format='{{json .State.Health.Status}}' #{@name}").delete('"')
        end

        # The network to use when testing against GDK in docker
        #
        # @return [String]
        def gdk_network
          return unless Runtime::Env.gdk_url

          'host'
        end

        # The IP address of the docker host when testing against GDK in docker
        #
        # @return [String]
        def gdk_host_ip
          return unless Runtime::Env.gdk_url

          Addrinfo.tcp(URI(Runtime::Env.gdk_url).host, nil).ip_address
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
      end
    end
  end
end
