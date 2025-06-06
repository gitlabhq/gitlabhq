# frozen_string_literal: true

class Oauth::ApplicationsController < Doorkeeper::ApplicationsController
  include Gitlab::GonHelper
  include PageLayoutHelper
  include OauthApplications
  include InitializesCurrentUserMode

  # Defined by the `Doorkeeper::ApplicationsController` and is redundant as we call `authenticate_user!` below. Not
  # defining or skipping this will result in a `403` response to all requests.
  skip_before_action :authenticate_admin!

  prepend_before_action :verify_user_oauth_applications_enabled, except: :index
  prepend_before_action :authenticate_user!
  before_action :add_gon_variables
  before_action :load_scopes, only: [:index, :create, :edit, :update]

  around_action :set_locale

  layout 'profile'

  def index
    set_index_vars
  end

  def show; end

  def create
    @application = Applications::CreateService.new(current_user, application_params).execute(request)

    if @application.persisted?
      flash[:notice] = I18n.t(:notice, scope: [:doorkeeper, :flash, :applications, :create])

      @created = true
      render :show
    else
      set_index_vars
      render :index
    end
  end

  def renew
    set_application

    @application.renew_secret

    if @application.save
      render json: { secret: @application.plaintext_secret }
    else
      render json: { errors: @application.errors }, status: :unprocessable_entity
    end
  end

  private

  def verify_user_oauth_applications_enabled
    return if Gitlab::CurrentSettings.user_oauth_applications?

    redirect_to user_settings_profile_path
  end

  def set_index_vars
    @applications = current_user.oauth_applications.keyset_paginate(cursor: params[:cursor])
    @applications_total_count = current_user.oauth_applications.count
    @authorized_tokens = current_user.oauth_authorized_tokens
                                     .latest_per_application
                                     .preload_application

    # Don't overwrite a value possibly set by `create`
    @application ||= Doorkeeper::Application.new
  end

  # Override Doorkeeper to scope to the current user
  def set_application
    @application = current_user.oauth_applications.find(params[:id])
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    render "errors/not_found", layout: "errors", status: :not_found
  end

  def application_params
    super.tap do |params|
      params[:owner] = current_user
    end
  end

  def set_locale(&block)
    Gitlab::I18n.with_user_locale(current_user, &block)
  end
end
