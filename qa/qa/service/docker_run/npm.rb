# frozen_string_literal: true

module QA
  module Service
    module DockerRun
      class Npm < Base
        def initialize(
          volume_host_path,
          gitlab_address_without_port:,
          package_name:,
          registry_scope:,
          package_project_id:,
          install_registry_url:,
          token:
        )
          @image = 'node:lts-alpine'
          @name = "qa-npm-#{SecureRandom.hex(8)}"
          @volume_host_path = volume_host_path
          @gitlab_address_without_port = gitlab_address_without_port
          @package_name = package_name
          @registry_scope = registry_scope
          @package_project_id = package_project_id
          @install_registry_url = install_registry_url
          @token = Shellwords.escape(token)

          super()
        end

        def publish_and_install!
          setup_container
          publish_package
          install_package
        ensure
          begin
            shell "docker stop #{name}"
          rescue StandardError => e
            QA::Runtime::Logger.warn("Stopping the container encountered an error: #{e}")
          end
        end

        private

        attr_reader :name, :image, :volume_host_path, :gitlab_address_without_port,
          :package_name, :registry_scope, :package_project_id, :install_registry_url, :token

        def registry_host
          gitlab_address_without_port.sub(%r{^https?://}, '')
        end

        def install_registry_host_path
          install_registry_url.sub(%r{^https?://}, '')
        end

        def setup_container
          shell <<~CMD.tr("\n", ' ')
            docker run -d --rm
            --network #{network}
            --hostname #{host_name}
            --name #{name}
            #{image} sh -c "sleep 300"
          CMD
          shell "docker cp #{volume_host_path}/. #{name}:/home/node"
        rescue StandardError => e
          QA::Runtime::Logger.warn("Setting up the container encountered an error: #{e}")
          raise
        end

        def publish_package
          shell <<~CMD.tr("\n", ' '), mask_secrets: [token]
            docker exec -t
            -e NPM_TOKEN=#{token}
            #{name} sh -c
            'echo //#{registry_host}/api/v4/projects/#{package_project_id}/packages/npm/:_authToken=$NPM_TOKEN > /home/node/.npmrc &&
             echo //#{install_registry_host_path}:_authToken=$NPM_TOKEN >> /home/node/.npmrc &&
             echo @#{registry_scope}:registry=#{install_registry_url} >> /home/node/.npmrc &&
             cd /home/node && npm publish'
          CMD
        rescue StandardError => e
          QA::Runtime::Logger.warn("Publishing the package encountered an error: #{e}")
          raise
        end

        def install_package
          Support::Retrier.retry_until(
            max_duration: 180, retry_on_exception: true, sleep_interval: 2
          ) do
            shell "docker exec -t #{name} sh -c 'cd /home/node && npm install #{package_name}'"
          end
        end
      end
    end
  end
end
