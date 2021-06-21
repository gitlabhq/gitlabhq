# frozen_string_literal: true

class Projects::ReleasesController < Projects::ApplicationController
  # Authorize
  before_action :require_non_empty_project, except: [:index]
  before_action :release, only: %i[edit show update downloads]
  before_action :authorize_read_release!
  # We have to check `download_code` permission because detail URL path
  # contains git-tag name.
  before_action :authorize_download_code!, except: [:index]
  before_action :authorize_update_release!, only: %i[edit update]
  before_action :authorize_create_release!, only: :new
  before_action only: :index do
    push_frontend_feature_flag(:releases_index_apollo_client, project, default_enabled: :yaml)
  end

  feature_category :release_orchestration

  def index
    respond_to do |format|
      format.html do
        require_non_empty_project
      end
      format.json { render json: releases }
    end
  end

  def downloads
    redirect_to link.url
  end

  private

  def releases
    ReleasesFinder.new(@project, current_user).execute
  end

  def authorize_update_release!
    access_denied! unless can?(current_user, :update_release, release)
  end

  def release
    @release ||= project.releases.find_by_tag!(sanitized_tag_name)
  end

  def link
    release.links.find_by_filepath!(sanitized_filepath)
  end

  def sanitized_filepath
    "/#{CGI.unescape(params[:filepath])}"
  end

  def sanitized_tag_name
    CGI.unescape(params[:tag])
  end
end
