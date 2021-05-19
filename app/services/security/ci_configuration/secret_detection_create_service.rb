# frozen_string_literal: true

module Security
  module CiConfiguration
    class SecretDetectionCreateService < ::Security::CiConfiguration::BaseCreateService
      private

      def action
        Security::CiConfiguration::SecretDetectionBuildAction.new(project.auto_devops_enabled?, existing_gitlab_ci_content).generate
      end

      def next_branch
        'set-secret-detection-config'
      end

      def message
        _('Configure Secret Detection in `.gitlab-ci.yml`, creating this file if it does not already exist')
      end

      def description
        _('Configure Secret Detection in `.gitlab-ci.yml` using the GitLab managed template. You can [add variable overrides](https://docs.gitlab.com/ee/user/application_security/secret_detection/#customizing-settings) to customize Secret Detection settings.')
      end
    end
  end
end
