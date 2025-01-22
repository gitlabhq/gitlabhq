# frozen_string_literal: true

class Admin::ApplicationsController < Admin::ApplicationController
  include OauthApplications

  before_action :set_application, only: [:show, :edit, :update, :renew, :destroy]
  before_action :load_scopes, only: [:new, :create, :edit, :update]

  feature_category :system_access

  def index
    applications = ApplicationsFinder.new.execute
    @applications = applications.keyset_paginate(cursor: params[:cursor])
    @applications_total_count = applications.count
  end

  def show; end

  def new
    @application = Doorkeeper::Application.new
  end

  def edit; end

  def create
    @application = Applications::CreateService.new(current_user, application_params).execute(request)

    if @application.persisted?
      flash[:notice] = I18n.t(:notice, scope: [:doorkeeper, :flash, :applications, :create])

      @created = true
      render :show
    else
      render :new
    end
  end

  def update
    if @application.update(application_params)
      redirect_to admin_application_path(@application), notice: _('Application was successfully updated.')
    else
      render :edit
    end
  end

  def renew
    @application.renew_secret

    if @application.save
      render json: { secret: @application.plaintext_secret }
    else
      render json: { errors: @application.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @application.destroy
    redirect_to admin_applications_url, status: :found, notice: _('Application was successfully destroyed.')
  end

  def reset_web_ide_oauth_application_settings
    success = ::WebIde::DefaultOauthApplication.reset_oauth_application_settings

    return render json: {}, status: :internal_server_error unless success

    render json: {}
  end

  private

  def set_application
    @application = ApplicationsFinder.new(id: params[:id]).execute
  end

  def permitted_params
    super << :trusted
  end

  def application_params
    super.tap do |params|
      params[:owner] = nil
    end
  end
end
