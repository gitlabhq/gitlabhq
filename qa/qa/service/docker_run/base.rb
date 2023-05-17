# frozen_string_literal: true

module QA
  module Service
    module DockerRun
      class Base
        include Service::Shellout

        def self.authenticated_registries
          @authenticated_registries ||= {}
        end

        def initialize
          @network = Runtime::Scenario.attributes[:network] || 'test'
          @runner_network = Runtime::Scenario.attributes[:runner_network] || @network
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
          shell "docker network inspect #{@network}"
        rescue CommandError
          'bridge'
        else
          @network
        end

        def runner_network
          shell "docker network inspect #{@runner_network}"
        rescue CommandError
          network
        else
          @runner_network
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
      end
    end
  end
end
