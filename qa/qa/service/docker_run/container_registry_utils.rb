# frozen_string_literal: true

module QA
  module Service
    module DockerRun
      class ContainerRegistryUtils < Base
        def tag_image(current_tag, new_tag)
          run_docker_command("tag #{current_tag} #{new_tag}")
        end

        def push_image(tag)
          run_docker_command("push #{tag}")
        end

        private

        def run_docker_command(command)
          shell("docker #{command}")
        end
      end
    end
  end
end
