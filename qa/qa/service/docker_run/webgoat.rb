# frozen_string_literal: true

require "socket"

module QA
  module Service
    module DockerRun
      class Webgoat < Base
        DEFAULT_SERVER_PORT = 8080
        DEFAULT_ADMIN_PORT = 9090

        def initialize
          @image = 'registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0@sha256:' \
            'bc09fe2e0721dfaeee79364115aeedf2174cce0947b9ae5fe7c33312ee019a4e'
          @name = 'webgoatserver'
          super
        end

        def register!
          return if running?

          command = %W[docker run -d --rm --network #{network} --name #{name} --hostname #{host_name}]
          command.push("-e", "WEBGOAT_PORT=#{host_network? ? server_port_host : DEFAULT_SERVER_PORT}")
          command.push("-e", "WEBGOAT_SSRF_PORT=#{host_network? ? admin_port_host : DEFAULT_ADMIN_PORT}")
          command.push("-p", DEFAULT_SERVER_PORT, "-p", DEFAULT_ADMIN_PORT) unless host_network?
          command.push(image)

          shell command.join(" ")
        end

        def ip_address
          @ip_address ||= shell("docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' #{name}")
            .strip
            .then { |addr| addr.empty? ? host_name : addr }
        end

        def public_port
          @public_port ||= if host_network?
                             server_port_host
                           elsif docker_network?
                             DEFAULT_SERVER_PORT
                           else
                             fetch_published_port(DEFAULT_SERVER_PORT)
                           end
        end

        def admin_port
          @admin_port ||= if host_network?
                            admin_port_host
                          elsif docker_network?
                            DEFAULT_ADMIN_PORT
                          else
                            fetch_published_port(DEFAULT_ADMIN_PORT)
                          end
        end

        private

        attr_reader :name, :image

        def server_port_host
          @server_port ||= random_port
        end

        def admin_port_host
          @admin_port_random ||= random_port
        end

        def host_network?
          network == "host"
        end

        def docker_network?
          host_name == "#{name}.#{network}"
        end

        def fetch_published_port(container_port)
          port = published_ports.split("\n").find { |line| line.start_with?(container_port.to_s) }.split(':').last
          raise("Could not find published #{container_port} port for container #{name}") unless port

          port.to_i
        end

        def published_ports
          @published_ports ||= shell("docker port #{name}").presence || raise(
            "Unable to fetch published ports for webgoat container #{name}"
          )
        end

        def random_port
          server = TCPServer.new('127.0.0.1', 0)
          port = server.addr[1]
          server.close
          port
        end
      end
    end
  end
end
