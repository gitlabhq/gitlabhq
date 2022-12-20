# frozen_string_literal: true

module Security
  module CiConfiguration
    class ContainerScanningBuildAction < BaseBuildAction
      private

      def update_existing_content!
        @existing_gitlab_ci_content['include'] = generate_includes
      end

      def template
        return 'Auto-DevOps.gitlab-ci.yml' if @auto_devops_enabled

        'Jobs/Container-Scanning.gitlab-ci.yml'
      end

      def comment
        <<~YAML
          #{super}
          # container_scanning:
          #   variables:
          #     DOCKER_IMAGE: ...
          #     DOCKER_USER: ...
          #     DOCKER_PASSWORD: ...
        YAML
      end
    end
  end
end
