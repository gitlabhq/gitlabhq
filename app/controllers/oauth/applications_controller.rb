class Oauth::ApplicationsController < Doorkeeper::ApplicationsController
  before_filter :authenticate_user!
  layout "profile"

  def index
    @applications = current_user.oauth_applications
  end

  def create
    @application = Doorkeeper::Application.new(application_params)

    if Doorkeeper.configuration.confirm_application_owner?
      @application.owner = current_user
    end

    if @application.save
      flash[:notice] = I18n.t(:notice, scope: [:doorkeeper, :flash, :applications, :create])
      redirect_to oauth_application_url(@application)
    else
      render :new
    end
  end

  def destroy
    if @application.destroy
      flash[:notice] = I18n.t(:notice, scope: [:doorkeeper, :flash, :applications, :destroy])
    end

    redirect_to profile_account_url
  end
end
