# frozen_string_literal: true

class Projects::ReleasesController < Projects::ApplicationController
  # Authorize
  before_action :require_non_empty_project, except: [:index]
  before_action :authorize_read_release!
  before_action do
    push_frontend_feature_flag(:release_edit_page, project)
  end

  def index
    respond_to do |format|
      format.html do
        require_non_empty_project
      end
      format.json { render json: releases }
    end
  end

  protected

  def releases
    ReleasesFinder.new(@project, current_user).execute
  end
end
