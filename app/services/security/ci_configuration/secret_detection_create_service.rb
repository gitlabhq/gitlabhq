# frozen_string_literal: true

module Security
  module CiConfiguration
    class SecretDetectionCreateService < ::Security::CiConfiguration::BaseCreateService
      attr_reader :params

      def initialize(project, current_user, params = {}, commit_on_default: false)
        super(project, current_user)
        @params = params
        @sast_also_enabled = @params.delete(:sast_also_enabled)

        @commit_on_default = commit_on_default
        @branch_name = project.default_branch if @commit_on_default
      end

      private

      def remove_branch_on_exception
        super unless @commit_on_default
      end

      def action
        Security::CiConfiguration::SecretDetectionBuildAction.new(
          project.auto_devops_enabled?,
          params,
          existing_gitlab_ci_content,
          project.ci_config_path
        ).generate
      end

      def next_branch
        'set-secret-detection-config'
      end

      def message
        if @sast_also_enabled
          _('Configure SAST and Secret Detection in `.gitlab-ci.yml`, creating this file if it does not already exist')
        else
          _('Configure Secret Detection in `.gitlab-ci.yml`, creating this file if it does not already exist')
        end
      end

      def description
        _('Configure Secret Detection in `.gitlab-ci.yml` using the GitLab managed template. You can [add variable overrides](https://docs.gitlab.com/user/application_security/secret_detection/pipeline/configure) to customize Secret Detection settings.')
      end

      def name
        'Secret Detection'
      end
    end
  end
end
