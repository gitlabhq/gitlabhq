# frozen_string_literal: true

module Security
  module CiConfiguration
    class SastCreateService < ::Security::CiConfiguration::BaseCreateService
      attr_reader :params

      def initialize(project, current_user, params, commit_on_default: false)
        super(project, current_user)
        @params = params

        @commit_on_default = commit_on_default
        @branch_name = project.default_branch if @commit_on_default
      end

      private

      def remove_branch_on_exception
        super unless @commit_on_default
      end

      def action
        Security::CiConfiguration::SastBuildAction.new(project.auto_devops_enabled?, params, existing_gitlab_ci_content, project.ci_config_path).generate
      end

      def next_branch
        'set-sast-config'
      end

      def message
        _('Configure SAST in `.gitlab-ci.yml`, creating this file if it does not already exist')
      end

      def description
        _('Configure SAST in `.gitlab-ci.yml` using the GitLab managed template. You can [add variable overrides](https://docs.gitlab.com/ee/user/application_security/sast/#customizing-the-sast-settings) to customize SAST settings.')
      end

      def name
        'SAST'
      end
    end
  end
end
