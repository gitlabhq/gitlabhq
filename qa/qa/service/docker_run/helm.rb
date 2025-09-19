# frozen_string_literal: true

module QA
  module Service
    module DockerRun
      class Helm < Base
        def initialize(
          volume_host_path,
          gitlab_address_with_port:, package_project_id:, channel:,
          package_name:, package_version:,
          username:, token:)
          @image = 'alpine/helm:3'
          @name = "qa-helm-#{SecureRandom.hex(8)}"
          @volume_host_path = volume_host_path

          @gitlab_address_with_port = gitlab_address_with_port
          @package_project_id = package_project_id
          @channel = channel
          @package_name = package_name
          @package_version = package_version
          @username = Shellwords.escape(username)
          @token = Shellwords.escape(token)

          super()
        end

        def publish_and_install!
          setup_container
          build_package
          publish_package
          update_repository
          download_package
        ensure
          # Stop the container when `helm pull` is finished otherwise
          # the sleeping container will hold onto the files in @volume_host_path,
          # which causes problems when they're created in a tmp dir
          # that we want to delete
          shell "docker stop #{name}"
        end

        private

        attr_reader :name,
          :gitlab_address_with_port, :channel, :package_project_id, :package_name, :package_version,
          :username, :token

        def download_url
          "#{gitlab_address_with_port}/api/v4/projects/#{package_project_id}/packages/helm/#{channel}"
        end

        def publish_url
          "#{gitlab_address_with_port}/api/v4/projects/#{package_project_id}/packages/helm/api/#{channel}/charts"
        end

        def setup_container
          shell <<~CMD.tr("\n", ' ')
            docker run -d --rm
            --network #{network}
            --hostname #{host_name}
            --name #{name}
            --entrypoint /bin/sh
            #{@image} -c "mkdir -p /workspace && sleep 300"
          CMD

          shell "docker cp #{@volume_host_path}/. #{name}:/workspace/#{package_name}"
        rescue StandardError => e
          QA::Runtime::Logger.warn("Setting up the container encountered an error: #{e}")
          raise
        end

        def build_package
          shell "docker exec -t #{name} sh -c 'cd /workspace && helm package #{package_name}'"
        rescue StandardError => e
          QA::Runtime::Logger.warn("Building the package encountered an error: #{e}")
          raise
        end

        def publish_package
          shell <<~CMD.tr("\n", ' ')
            docker exec -t #{name} sh -c
            'cd /workspace &&
             curl --fail-with-body
             --request POST
             --form "chart=@#{package_name}-#{package_version}.tgz"
             --user #{username}:#{token}
             "#{publish_url}"'
          CMD
        rescue StandardError => e
          QA::Runtime::Logger.warn("Publishing the package encountered an error: #{e}")
          raise
        end

        def update_repository
          shell <<~CMD.tr("\n", ' ')
            docker exec -t #{name} sh -c
            'helm repo add
             --username #{username}
             --password #{token}
             gitlab_qa #{download_url} &&
             helm repo update'
          CMD
        rescue StandardError => e
          QA::Runtime::Logger.warn("Updating the repository encountered an error: #{e}")
          raise
        end

        def download_package
          Support::Retrier.retry_until(
            max_duration: 180, retry_on_exception: true, sleep_interval: 2
          ) do
            shell "docker exec -t #{name} sh -c 'helm repo update && helm pull gitlab_qa/#{package_name}'"
          end
        end
      end
    end
  end
end
