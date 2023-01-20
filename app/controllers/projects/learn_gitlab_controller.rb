# frozen_string_literal: true

module Projects
  class LearnGitlabController < Projects::ApplicationController
    before_action :authenticate_user!
    before_action :verify_learn_gitlab_available!
    before_action :enable_invite_for_help_continuous_onboarding_experiment
    before_action :enable_video_tutorials_continuous_onboarding_experiment

    feature_category :user_profile
    urgency :low, [:index]

    def index; end

    private

    def verify_learn_gitlab_available!
      access_denied! unless helpers.learn_gitlab_enabled?(project)
    end

    def enable_invite_for_help_continuous_onboarding_experiment
      return unless current_user.can?(:admin_group_member, project.namespace)

      experiment(:invite_for_help_continuous_onboarding, namespace: project.namespace) do |e|
        e.candidate {}
      end
    end

    def enable_video_tutorials_continuous_onboarding_experiment
      experiment(:video_tutorials_continuous_onboarding, namespace: project&.namespace).publish
    end
  end
end
