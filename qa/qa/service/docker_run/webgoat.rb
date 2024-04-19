# frozen_string_literal: true

module QA
  module Service
    module DockerRun
      class Webgoat < Base
        def initialize
          @image = 'registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0@sha256:' \
                   'bc09fe2e0721dfaeee79364115aeedf2174cce0947b9ae5fe7c33312ee019a4e'
          @name = 'webgoatserver'
          super
        end

        # We should be on the same network as the runner
        def register!
          shell <<~CMD.tr("\n", ' ')
            docker run -d --rm
            --network #{network}
            --name #{name}
            --hostname #{host_name}
            --publish 8080:8080
            --publish 9090:9090
            #{image}
          CMD
        end

        # DAST/ZAP DIND needs to reference the Webgoat container by IP address
        def ip_address
          ip_address = `docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' #{name}`
                         .strip

          return host_name if ip_address.empty?

          ip_address
        end

        private

        attr_reader :name, :image
      end
    end
  end
end
