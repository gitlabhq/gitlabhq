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

  def show
    @created = get_created_session if Feature.disabled?('hash_oauth_secrets')
  end

  def create
    @application = Applications::CreateService.new(current_user, application_params).execute(request)

    if @application.persisted?
      flash[:notice] = I18n.t(:notice, scope: [:doorkeeper, :flash, :applications, :create])

      if Feature.enabled?('hash_oauth_secrets')
        @created = true
        render :show
      else
        set_created_session

        redirect_to oauth_application_url(@application)
      end
    else
      set_index_vars
      render :index
    end
  end

  def renew
    set_application

    @application.renew_secret

    if @application.save
      flash.now[:notice] = s_('AuthorizedApplication|Application secret was successfully updated.')
      render :show
    else
      redirect_to oauth_application_url(@application)
    end
  end

  private

  def verify_user_oauth_applications_enabled
    return if Gitlab::CurrentSettings.user_oauth_applications?

    redirect_to profile_path
  end

  def set_index_vars
    @applications = current_user.oauth_applications.load
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
