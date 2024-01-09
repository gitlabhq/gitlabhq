# frozen_string_literal: true

module QA
  module Service
    module DockerRun
      class Gitlab < Base
        attr_reader :external_url, :name

        # @param [String] name
        # @param [String] omnibus_config
        # @param [String] image
        # @param [String] ports Docker-formatted port exposition
        # @see ports https://docs.docker.com/engine/reference/commandline/run/#publish
        # @param [String] external_url
        def initialize(name:, omnibus_config: '', image: '', ports: '80:80', external_url: Runtime::Env.gitlab_url)
          @image = image
          @name = name
          @omnibus_configuration = omnibus_config
          @ports = ports
          @external_url = external_url
          super()
        end

        def login
          return unless release_variables_available?

          super(Runtime::Env.release_registry_url,
            user: Runtime::Env.release_registry_username,
            password: Runtime::Env.release_registry_password)
        end

        def register!
          shell <<~CMD.tr("\n", ' ')
            docker run -d --rm
            --network #{network}
            --hostname #{host_name}
            --publish #{@ports}
            #{RUBY_PLATFORM.include?('arm64') ? '--platform linux/amd64' : ''}
            --env GITLAB_OMNIBUS_CONFIG="#{@omnibus_configuration}"
            --name #{@name}
            #{@image}
          CMD
        end

        # Copy logs for GitLab services from the Docker container to the test framework's tmp folder
        def extract_service_logs
          copy(from: "#{@name}:/var/log/gitlab", to: Runtime::Path.qa_tmp(@name))
        end

        private

        def release_variables_available?
          Runtime::Env.release_registry_url &&
            Runtime::Env.release_registry_username &&
            Runtime::Env.release_registry_password
        end
      end
    end
  end
end
