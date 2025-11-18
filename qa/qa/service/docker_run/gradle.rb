# frozen_string_literal: true

module QA
  module Service
    module DockerRun
      class Gradle < Base
        def initialize(volume_host_path, artifact_id:, package_version:)
          @image = 'gradle:8-alpine'
          @name = "qa-gradle-#{SecureRandom.hex(8)}"
          @volume_host_path = volume_host_path
          @artifact_id = artifact_id
          @package_version = package_version

          super()
        end

        def publish_and_install!
          setup_container
          publish_package
          download_package
        ensure
          # Stop the container when `gradle build` is finished otherwise
          # the sleeping container will hold onto the files in @volume_host_path,
          # which causes problems when they're created in a tmp dir
          # that we want to delete
          begin
            shell "docker stop #{name}"
          rescue StandardError => e
            QA::Runtime::Logger.warn("Stopping the container encountered an error: #{e}")
          end
        end

        private

        attr_reader :name, :image, :volume_host_path, :artifact_id, :package_version

        def setup_container
          shell <<~CMD.tr("\n", ' ')
            docker run -d --rm
            --network #{network}
            --hostname #{host_name}
            --name #{name}
            #{image} sh -c "sleep 300"
          CMD
          shell "docker cp #{volume_host_path}/. #{name}:/home/gradle/#{artifact_id}"
        rescue StandardError => e
          QA::Runtime::Logger.warn("Setting up the container encountered an error: #{e}")
          raise
        end

        def publish_package
          shell "docker exec -t #{name} sh -c 'cd /home/gradle/#{artifact_id} && cp publish.gradle build.gradle'"
          shell "docker exec -t #{name} sh -c 'cd /home/gradle/#{artifact_id} && gradle publish'"
        rescue StandardError => e
          QA::Runtime::Logger.warn("Publishing the package encountered an error: #{e}")
          raise
        end

        def download_package
          Support::Retrier.retry_until(
            max_duration: 180, retry_on_exception: true, sleep_interval: 2
          ) do
            shell "docker exec -t #{name} sh -c 'cd /home/gradle/#{artifact_id} && cp install.gradle build.gradle'"
            shell "docker exec -t #{name} sh -c 'cd /home/gradle/#{artifact_id} && gradle build'"
          end
        end
      end
    end
  end
end
