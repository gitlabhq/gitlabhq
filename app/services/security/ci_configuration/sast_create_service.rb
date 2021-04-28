# frozen_string_literal: true

module Security
  module CiConfiguration
    class SastCreateService < ::Security::CiConfiguration::BaseCreateService
      attr_reader :params

      def initialize(project, current_user, params)
        super(project, current_user)
        @params = params
      end

      private

      def action
        Security::CiConfiguration::SastBuildAction.new(project.auto_devops_enabled?, params, existing_gitlab_ci_content).generate
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
    end
  end
end
