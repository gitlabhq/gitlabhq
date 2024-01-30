# frozen_string_literal: true

module Security
  module CiConfiguration
    class ContainerScanningCreateService < ::Security::CiConfiguration::BaseCreateService
      private

      def action
        Security::CiConfiguration::ContainerScanningBuildAction.new(
          project.auto_devops_enabled?,
          existing_gitlab_ci_content,
          project.ci_config_path
        ).generate
      end

      def next_branch
        'set-container-scanning-config'
      end

      def message
        _('Configure Container Scanning in `.gitlab-ci.yml`, creating this file if it does not already exist')
      end

      def description
        _('Configure Container Scanning in `.gitlab-ci.yml` using the GitLab managed template. You can [add variable overrides](https://docs.gitlab.com/ee/user/application_security/container_scanning/#customizing-the-container-scanning-settings) to customize Container Scanning settings.')
      end

      def name
        'Container Scanning'
      end
    end
  end
end
