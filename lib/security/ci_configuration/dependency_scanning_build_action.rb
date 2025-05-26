# frozen_string_literal: true

module Security
  module CiConfiguration
    class DependencyScanningBuildAction < BaseBuildAction
      private

      def update_existing_content!
        add_stages!([Security::CiConfiguration::DEFAULT_TEST_STAGE]) unless @auto_devops_enabled
        @existing_gitlab_ci_content['include'] = generate_includes
      end

      def template
        return 'Auto-DevOps.gitlab-ci.yml' if @auto_devops_enabled

        'Security/Dependency-Scanning.gitlab-ci.yml'
      end
    end
  end
end
