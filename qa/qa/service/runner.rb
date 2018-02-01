require 'securerandom'

module QA
  module Service
    class Runner
      include Scenario::Actable
      include Service::Shellout

      attr_accessor :token, :address, :tags, :image, :executor, :docker_image

      def initialize(name)
        @name = name || "qa-runner-#{SecureRandom.hex(4)}"
        @network = Runtime::Scenario.attributes[:network] || 'test'
        @tags = %w[qa test]
        @image = 'gitlab/gitlab-runner:alpine'
        @executor = 'shell'
        @docker_image = 'ubuntu/16.04'
      end

      def pull
        shell "docker pull #{@image}"
      end

      def register!
        shell <<~CMD.tr("\n", ' ')
          docker run -d --rm --entrypoint=/bin/sh
          --network #{@network} --name #{@name}
          -e CI_SERVER_URL=#{@address}
          -e REGISTER_NON_INTERACTIVE=true
          -e REGISTRATION_TOKEN=#{@token}
          -e RUNNER_EXECUTOR=#{@executor}
          -e DOCKER_IMAGE=#{@docker_image}
          -e RUNNER_TAG_LIST=#{@tags.join(',')}
          -e RUNNER_NAME=#{@name}
          #{@image} -c '#{docker_commands}'
        CMD
      end

      def remove!
        shell "docker rm -f #{@name}"
      end

      private

      def docker_commands
        commands = [
          'gitlab-runner register',
          'gitlab-runner run'
        ]

        if @executor == 'docker'
          commands.unshift('apt-get install -y docker-ce')
        end

        commands.join(' && ')
      end
    end
  end
end
