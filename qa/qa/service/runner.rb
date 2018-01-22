require 'securerandom'

module QA
  module Service
    class Runner
      include Scenario::Actable
      include Service::Shellout

      attr_accessor :token, :address, :tags, :image, :name

      def initialize
        @image = 'gitlab/gitlab-runner:alpine'
        @name = "qa-runner-#{SecureRandom.hex(4)}"
      end

      def pull
        shell "docker pull #{@image}"
      end

      def register!
        ##
        # TODO, this assumes that `test` network exists, because we know that
        # gitlab-qa environment orchestration tool creates it.
        #
        shell <<~CMD.tr("\n", ' ')
          docker run -d --rm --entrypoint=/bin/sh
          --network test --name #{@name}
          -e CI_SERVER_URL=#{@address}
          -e REGISTER_NON_INTERACTIVE=true
          -e REGISTRATION_TOKEN=#{@token}
          -e RUNNER_EXECUTOR=shell
          -e RUNNER_TAG_LIST=#{@tags.to_a.join(',')}
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
