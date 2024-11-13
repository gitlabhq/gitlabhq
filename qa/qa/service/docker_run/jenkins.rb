# frozen_string_literal: true

module QA
  module Service
    module DockerRun
      class Jenkins < Base
        include Mixins::ThirdPartyDocker

        attr_reader :port

        def initialize
          @image = "#{third_party_repository}/jenkins:latest"
          @name = 'jenkins-server'
          @port = '8080'
          super
        end

        def network
          @network || 'test'
        end

        def username
          Runtime::Env.jenkins_admin_username
        end

        def password
          Runtime::Env.jenkins_admin_password
        end

        def host_address
          "http://#{host_name}:#{@port}"
        end

        def register!
          authenticate_third_party

          command = <<~CMD.tr("\n", ' ')
            docker run -d --rm
            --network #{network}
            --hostname #{host_name}
            --name #{@name}
            --env JENKINS_USER=#{username}
            --env JENKINS_PASS=#{password}
            --publish #{@port}:8080
            --publish 50000:50000
            #{@image}
          CMD

          shell(command, mask_secrets: [password])

          wait_for_running
        end

        private

        def wait_for_running
          Support::Waiter.wait_until(max_duration: 10, reload_page: false, raise_on_failure: false) do
            running?
          end
        end
      end
    end
  end
end
