# frozen_string_literal: true

module Security
  module CiConfiguration
    class DependencyScanningCreateService < ::Security::CiConfiguration::BaseCreateService
      private

      def action
        Security::CiConfiguration::DependencyScanningBuildAction.new(
          project.auto_devops_enabled?,
          existing_gitlab_ci_content,
          project.ci_config_path
        ).generate
      end

      def next_branch
        'set-dependency-scanning-config'
      end

      def message
        _('Configure Dependency Scanning in `.gitlab-ci.yml`, creating this file if it does not already exist')
      end

      def description
        _('Configure Dependency Scanning in `.gitlab-ci.yml` using the GitLab managed template. You can [add variable overrides](https://docs.gitlab.com/ee/user/application_security/dependency_scanning/#customizing-the-dependency-scanning-settings) to customize Dependency Scanning settings.')
      end

      def name
        'Dependency Scanning'
      end
    end
  end
end
