# frozen_string_literal: true

module QA
  module Service
    module DockerRun
      class Gitlab < Base
        def initialize(name:, omnibus_config: '', image: '')
          @image = image
          @name = name
          @omnibus_configuration = omnibus_config
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
            --publish 80:80
            #{RUBY_PLATFORM.include?('arm64') ? '--platform linux/amd64' : ''}
            --env GITLAB_OMNIBUS_CONFIG="#{@omnibus_configuration}"
            --name #{@name}
            #{@image}
          CMD
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
