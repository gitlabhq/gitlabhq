# frozen_string_literal: true

module Registrations
  class ExperienceLevelsController < ApplicationController
    layout 'minimal'

    before_action :ensure_namespace_path_param

    feature_category :onboarding

    def update
      current_user.experience_level = params[:experience_level]

      if current_user.save
        hide_advanced_issues

        if learn_gitlab.available?
          redirect_to namespace_project_board_path(params[:namespace_path], learn_gitlab.project, learn_gitlab.board)
        else
          redirect_to group_path(params[:namespace_path])
        end
      else
        render :show
      end
    end

    private

    def ensure_namespace_path_param
      redirect_to root_path unless params[:namespace_path].present?
    end

    def hide_advanced_issues
      return unless current_user.user_preference.novice?
      return unless learn_gitlab.available?

      Boards::UpdateService.new(learn_gitlab.project, current_user, label_ids: [learn_gitlab.label.id]).execute(learn_gitlab.board)
    end

    def learn_gitlab
      @learn_gitlab ||= LearnGitlab::Project.new(current_user)
    end
  end
end
