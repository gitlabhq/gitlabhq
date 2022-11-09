# frozen_string_literal: true

class Projects::LearnGitlabController < Projects::ApplicationController
  before_action :authenticate_user!
  before_action :check_experiment_enabled?
  before_action :enable_invite_for_help_continuous_onboarding_experiment
  before_action :enable_video_tutorials_continuous_onboarding_experiment

  feature_category :users
  urgency :low, [:index]

  def index
  end

  private

  def check_experiment_enabled?
    return access_denied! unless helpers.learn_gitlab_enabled?(project)
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
