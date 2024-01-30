# frozen_string_literal: true

module Security
  module CiConfiguration
    class SastIacCreateService < ::Security::CiConfiguration::BaseCreateService
      private

      def action
        Security::CiConfiguration::SastIacBuildAction.new(
          project.auto_devops_enabled?,
          existing_gitlab_ci_content,
          project.ci_config_path
        ).generate
      end

      def next_branch
        'set-sast-iac-config'
      end

      def message
        _('Configure SAST IaC in `.gitlab-ci.yml`, creating this file if it does not already exist')
      end

      def description
        _('Configure SAST IaC in `.gitlab-ci.yml` using the GitLab managed template. You can [add variable overrides](https://docs.gitlab.com/ee/user/application_security/sast/#customizing-the-sast-settings) to customize SAST IaC settings.')
      end

      def name
        'SAST IaC'
      end
    end
  end
end
