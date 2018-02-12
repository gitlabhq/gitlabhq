require 'securerandom'

module QA
  module Service
    class Runner
      include Scenario::Actable
      include Service::Shellout

      attr_accessor :token, :address, :tags, :image

      def initialize(name)
        @image = 'gitlab/gitlab-runner:alpine'
        @name = name || "qa-runner-#{SecureRandom.hex(4)}"
        @network = Runtime::Scenario.attributes[:network] || 'test'
        @tags = %w[qa test]
      end

      def network
        shell "docker network inspect #{@network}"
      rescue CommandError
        'bridge'
      else
        @network
      end

      def pull
        shell "docker pull #{@image}"
      end

      def register!
        shell <<~CMD.tr("\n", ' ')
          docker run -d --rm --entrypoint=/bin/sh
          --network #{network} --name #{@name}
          -e CI_SERVER_URL=#{@address}
          -e REGISTER_NON_INTERACTIVE=true
          -e REGISTRATION_TOKEN=#{@token}
          -e RUNNER_EXECUTOR=shell
          -e RUNNER_TAG_LIST=#{@tags.join(',')}
          -e RUNNER_NAME=#{@name}
          #{@image} -c 'gitlab-runner register && gitlab-runner run'
        CMD
      end

      def remove!
        shell "docker rm -f #{@name}"
      end
    end
  end
end
