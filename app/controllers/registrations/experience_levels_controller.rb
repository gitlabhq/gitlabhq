# frozen_string_literal: true

module Registrations
  class ExperienceLevelsController < ApplicationController
    layout 'devise_experimental_onboarding_issues'

    before_action :check_experiment_enabled
    before_action :ensure_namespace_path_param

    feature_category :navigation

    def update
      current_user.experience_level = params[:experience_level]

      if current_user.save
        hide_advanced_issues
        record_experiment_user(:default_to_issues_board)

        if experiment_enabled?(:default_to_issues_board) && learn_gitlab.available?
          redirect_to namespace_project_board_path(params[:namespace_path], learn_gitlab.project, learn_gitlab.board)
        else
          redirect_to group_path(params[:namespace_path])
        end
      else
        render :show
      end
    end

    private

    def check_experiment_enabled
      access_denied! unless experiment_enabled?(:onboarding_issues)
    end

    def ensure_namespace_path_param
      redirect_to root_path unless params[:namespace_path].present?
    end

    def hide_advanced_issues
      return unless current_user.user_preference.novice?
      return unless learn_gitlab.available?

      Boards::UpdateService.new(learn_gitlab.project, current_user, label_ids: [learn_gitlab.label.id]).execute(learn_gitlab.board)
    end

    def learn_gitlab
      @learn_gitlab ||= LearnGitlab.new(current_user)
    end
  end
end
