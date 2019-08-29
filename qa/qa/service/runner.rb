# frozen_string_literal: true

require 'securerandom'

module QA
  module Service
    class Runner
      include Service::Shellout

      attr_accessor :token, :address, :tags, :image, :run_untagged
      attr_writer :config

      def initialize(name)
        @image = 'gitlab/gitlab-runner:alpine'
        @name = name || "qa-runner-#{SecureRandom.hex(4)}"
        @network = Runtime::Scenario.attributes[:network] || 'test'
        @tags = %w[qa test]
        @run_untagged = false
      end

      def config
        @config ||= <<~END
          concurrent = 1
          check_interval = 0

          [session_server]
            session_timeout = 1800
        END
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
          -p 8093:8093
          -e CI_SERVER_URL=#{@address}
          -e REGISTER_NON_INTERACTIVE=true
          -e REGISTRATION_TOKEN=#{@token}
          -e RUNNER_EXECUTOR=shell
          -e RUNNER_TAG_LIST=#{@tags.join(',')}
          -e RUNNER_NAME=#{@name}
          #{@image} -c "#{register_command}"
        CMD
      end

      def remove!
        shell "docker rm -f #{@name}"
      end

      private

      def register_command
        <<~CMD
          printf '#{config.chomp.gsub(/\n/, "\\n").gsub('"', '\"')}' > /etc/gitlab-runner/config.toml &&
          gitlab-runner register --run-untagged=#{@run_untagged} &&
          gitlab-runner run
        CMD
      end
    end
  end
end
