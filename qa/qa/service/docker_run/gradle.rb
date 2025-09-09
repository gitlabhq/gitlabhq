# frozen_string_literal: true

module QA
  module Service
    module DockerRun
      class Gradle < Base
        def initialize(volume_host_path, artifact_id)
          @image = 'gradle:8-jdk17'
          @name = "qa-gradle-#{SecureRandom.hex(8)}"
          @volume_host_path = volume_host_path
          @artifact_id = artifact_id

          super()
        end

        def publish_and_install!
          shell <<~CMD.tr("\n", ' ')
            docker run -d --rm
            --network #{network}
            --hostname #{host_name}
            --name #{@name}
            #{@image} sh -c "sleep 300"
          CMD
          shell "docker cp #{@volume_host_path}/. #{@name}:/home/gradle/#{@artifact_id}"
          shell "docker exec -t #{@name} sh -c 'cd /home/gradle/#{@artifact_id} && gradle publish'"
          shell "docker exec -t #{@name} sh -c 'cd /home/gradle/#{@artifact_id} && gradle publishToMavenLocal'"

          # Stop the container when `gradle build` is finished otherwise
          # the sleeping container will hold onto the files in @volume_host_path,
          # which causes problems when they're created in a tmp dir
          # that we want to delete
          shell "docker stop #{@name}"
        end
      end
    end
  end
end
