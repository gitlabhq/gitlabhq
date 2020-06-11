# frozen_string_literal: true

module Registrations
  class ExperienceLevelsController < ApplicationController
    # This will need to be changed to simply 'devise' as part of
    # https://gitlab.com/gitlab-org/growth/engineering/issues/64
    layout 'devise_experimental_separate_sign_up_flow'

    before_action :check_experiment_enabled
    before_action :ensure_namespace_path_param

    def update
      current_user.experience_level = params[:experience_level]

      if current_user.save
        flash[:message] = I18n.t('devise.registrations.signed_up')
        redirect_to group_path(params[:namespace_path])
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
  end
end
