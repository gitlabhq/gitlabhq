# frozen_string_literal: true

require 'resolv'
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
          @executor_image = 'registry.gitlab.com/gitlab-org/gitlab-build-images:gitlab-qa-alpine-ruby-2.7'

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
            docker run -d --rm --network #{runner_network} --name #{@name}
            #{'-v /var/run/docker.sock:/var/run/docker.sock' if @executor == :docker}
            --privileged
            #{@image}  #{add_gitlab_tls_cert if @address.include? "https"} && docker exec --detach #{@name} sh -c "#{register_command}"
          CMD

          # Prove airgappedness
          if runner_network == 'airgapped'
            shell("docker exec #{@name} sh -c '#{prove_airgap}'")
          end
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
            args << "--docker-volumes=/certs/client"
          end

          <<~CMD.strip
            printf '#{config.chomp.gsub(/\n/, "\\n").gsub('"', '\"')}' > /etc/gitlab-runner/config.toml &&
            gitlab-runner register \
              #{args.join(' ')} &&
            gitlab-runner run
          CMD
        end

        # Ping Cloudflare DNS, should fail
        # Ping Registry, should fail to resolve
        def prove_airgap
          gitlab_ip = Resolv.getaddress 'registry.gitlab.com'
          <<~CMD
            echo "Checking airgapped connectivity..."
            nc -zv -w 10 #{gitlab_ip} 80 && (echo "Airgapped network faulty. Connectivity netcat check failed." && exit 1) || (echo "Connectivity netcat check passed." && exit 0)
            wget --retry-connrefused --waitretry=1 --read-timeout=15 --timeout=10 -t 2 http://registry.gitlab.com > /dev/null 2>&1 && (echo "Airgapped network faulty. Connectivity wget check failed." && exit 1) || (echo "Airgapped network confirmed. Connectivity wget check passed." && exit 0)
          CMD
        end

        def add_gitlab_tls_cert
          gitlab_tls_certificate = Tempfile.new('gitlab-cert')
          gitlab_tls_certificate.write(Runtime::Env.gitlab_tls_certificate)
          gitlab_tls_certificate.close

          <<~CMD
            && docker cp #{gitlab_tls_certificate.path} #{@name}:/etc/gitlab-runner/certs/gitlab.test.crt
          CMD
        end
      end
    end
  end
end
