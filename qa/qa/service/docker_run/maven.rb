# frozen_string_literal: true

module QA
  module Service
    module DockerRun
      class Maven < Base
        def initialize(volume_host_path)
          @image = 'maven:3.6.2-ibmjava-8-alpine'
          @name = "qa-maven-#{SecureRandom.hex(8)}"
          @volume_host_path = volume_host_path

          super()
        end

        def publish!
          # When we run the tests via gitlab-qa, we use docker-in-docker
          # which means that host of a volume mount would be the host that
          # started the gitlab-qa QA container (e.g., the CI runner),
          # not the gitlab-qa container itself. That means we can't
          # mount a volume from the file system inside the gitlab-qa
          # container.
          #
          # Instead, we copy the files into the container.
          shell <<~CMD.tr("\n", ' ')
            docker run -d --rm
            --network #{network}
            --hostname #{host_name}
            --name #{@name}
            --volume #{@volume_host_path}:/home/maven
            #{@image} sh -c "sleep 300"
          CMD
          shell "docker cp #{@volume_host_path}/. #{@name}:/home/maven"
          shell "docker exec -t #{@name} sh -c 'cd /home/maven && mvn deploy -s settings.xml'"

          # Stop the container when `mvn deploy` is finished otherwise
          # the sleeping container will hold onto the files in @volume_host_path,
          # which causes problems when they're created in a tmp dir
          # that we want to delete
          shell "docker stop #{@name}"
        end
      end
    end
  end
end
