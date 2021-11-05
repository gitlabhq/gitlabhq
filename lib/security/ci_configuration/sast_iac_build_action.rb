# frozen_string_literal: true

module Security
  module CiConfiguration
    class SastIacBuildAction < BaseBuildAction
      private

      def update_existing_content!
        @existing_gitlab_ci_content['include'] = generate_includes
      end

      def template
        return 'Auto-DevOps.gitlab-ci.yml' if @auto_devops_enabled

        'Security/SAST-IaC.latest.gitlab-ci.yml'
      end
    end
  end
end
