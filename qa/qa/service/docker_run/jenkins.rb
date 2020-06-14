# frozen_string_literal: true

module QA
  module Service
    module DockerRun
      class Jenkins < Base
        def initialize
          @image = 'registry.gitlab.com/gitlab-org/gitlab-qa/jenkins-gitlab:version1'
          @name = 'jenkins-server'
          @port = '8080'
          super()
        end

        def host_address
          "http://#{host_name}:#{@port}"
        end

        def host_name
          if !QA::Runtime::Env.running_in_ci? && !runner_network.equal?('airgapped')
            'localhost'
          end

          super
        end

        def register!
          command = <<~CMD.tr("\n", ' ')
            docker run -d --rm
            --network #{network}
            --hostname #{host_name}
            --name #{@name}
            --env JENKINS_HOME=jenkins_home
            --publish #{@port}:8080
            --publish 50000:50000
            #{@image}
          CMD

          if !QA::Runtime::Env.running_in_ci? && !runner_network.equal?('airgapped')
            command.gsub!("--network #{network} ", '')
          end

          shell command
        end
      end
    end
  end
end
