class Oauth::ApplicationsController < Doorkeeper::ApplicationsController
  include Gitlab::CurrentSettings
  include Gitlab::GonHelper
  include PageLayoutHelper

  before_action :verify_user_oauth_applications_enabled
  before_action :authenticate_user!
  before_action :add_gon_variables

  layout 'profile'

  def index
    set_index_vars
  end

  def create
    @application = Doorkeeper::Application.new(application_params)

    @application.owner = current_user

    if @application.save
      flash[:notice] = I18n.t(:notice, scope: [:doorkeeper, :flash, :applications, :create])
      redirect_to oauth_application_url(@application)
    else
      set_index_vars
      render :index
    end
  end

  private

  def verify_user_oauth_applications_enabled
    return if current_application_settings.user_oauth_applications?

    redirect_to applications_profile_url
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
end
