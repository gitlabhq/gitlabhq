class Oauth::ApplicationsController < Doorkeeper::ApplicationsController
  include Gitlab::GonHelper
  include Gitlab::Allowable
  include PageLayoutHelper
  include OauthApplications

  before_action :verify_user_oauth_applications_enabled
  before_action :authenticate_user!
  before_action :add_gon_variables
  before_action :load_scopes, only: [:index, :create, :edit]

  helper_method :can?

  layout 'profile'

  def index
    set_index_vars
  end

  def create
    @application = Applications::CreateService.new(current_user, create_application_params).execute(request)

    if @application.persisted?
      flash[:notice] = I18n.t(:notice, scope: [:doorkeeper, :flash, :applications, :create])

      redirect_to oauth_application_url(@application)
    else
      set_index_vars
      render :index
    end
  end

  private

  def verify_user_oauth_applications_enabled
    return if Gitlab::CurrentSettings.user_oauth_applications?

    redirect_to profile_path
  end

  def set_index_vars
    @applications = current_user.oauth_applications
    @authorized_tokens = current_user.oauth_authorized_tokens
    @authorized_anonymous_tokens = @authorized_tokens.reject(&:application)
    @authorized_apps = @authorized_tokens.map(&:application).uniq.reject(&:nil?)

    # Don't overwrite a value possibly set by `create`
    @application ||= Doorkeeper::Application.new
  end

  # Override Doorkeeper to scope to the current user
  def set_application
    @application = current_user.oauth_applications.find(params[:id])
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    render "errors/not_found", layout: "errors", status: 404
  end

  def create_application_params
    application_params.tap do |params|
      params[:owner] = current_user
    end
  end
end
