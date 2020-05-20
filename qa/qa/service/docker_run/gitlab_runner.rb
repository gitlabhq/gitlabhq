# frozen_string_literal: true

require 'securerandom'

module QA
  module Service
    module DockerRun
      class GitlabRunner < Base
        attr_reader :tags
        attr_accessor :token, :address, :image, :run_untagged
        attr_writer :config, :executor, :executor_image

        CONFLICTING_VARIABLES_MESSAGE = <<~MSG
          There are conflicting options preventing the runner from starting.
          %s cannot be specified if %s is %s
        MSG

        def initialize(name)
          @image = 'gitlab/gitlab-runner:alpine'
          @name = name || "qa-runner-#{SecureRandom.hex(4)}"
          @run_untagged = true
          @executor = :shell
          @executor_image = 'registry.gitlab.com/gitlab-org/gitlab-build-images:gitlab-qa-alpine-ruby-2.6'

          super()
        end

        def config
          @config ||= <<~END
            concurrent = 1
            check_interval = 0

            [session_server]
              session_timeout = 1800
          END
        end

        def register!
          shell <<~CMD.tr("\n", ' ')
            docker run -d --rm --entrypoint=/bin/sh
            --network #{network} --name #{@name}
            #{'-v /var/run/docker.sock:/var/run/docker.sock' if @executor == :docker}
            --privileged
            #{@image} -c "#{register_command}"
          CMD
        end

        def tags=(tags)
          @tags = tags
          @run_untagged = false
        end

        private

        def register_command
          args = []
          args << '--non-interactive'
          args << "--name #{@name}"
          args << "--url #{@address}"
          args << "--registration-token #{@token}"

          args << if run_untagged
                    raise CONFLICTING_VARIABLES_MESSAGE % [:tags=, :run_untagged, run_untagged] if @tags&.any?

                    '--run-untagged=true'
                  else
                    raise 'You must specify tags to run!' unless @tags&.any?

                    "--tag-list #{@tags.join(',')}"
                  end

          args << "--executor #{@executor}"

          if @executor == :docker
            args << "--docker-image #{@executor_image}"
            args << '--docker-tlsverify=false'
            args << '--docker-privileged=true'
            args << "--docker-network-mode=#{network}"
          end

          <<~CMD.strip
            printf '#{config.chomp.gsub(/\n/, "\\n").gsub('"', '\"')}' > /etc/gitlab-runner/config.toml &&
            gitlab-runner register \
              #{args.join(' ')} &&
            gitlab-runner run
          CMD
        end
      end
    end
  end
end
