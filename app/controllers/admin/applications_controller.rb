class Admin::ApplicationsController < Admin::ApplicationController
  include OauthApplications

  before_action :set_application, only: [:show, :edit, :update, :destroy]
  before_action :load_scopes, only: [:new, :create, :edit, :update]

  def index
    @applications = Doorkeeper::Application.where("owner_id IS NULL")
  end

  def show
  end

  def new
    @application = Doorkeeper::Application.new
  end

  def edit
  end

  def create
    @application = Applications::CreateService.new(current_user, application_params).execute(request)

    if @application.persisted?
      flash[:notice] = I18n.t(:notice, scope: [:doorkeeper, :flash, :applications, :create])

      redirect_to admin_application_url(@application)
    else
      render :new
    end
  end

  def update
    if @application.update(application_params)
      redirect_to admin_application_path(@application), notice: 'Application was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @application.destroy
    redirect_to admin_applications_url, status: 302, notice: 'Application was successfully destroyed.'
  end

  private

  def set_application
    @application = Doorkeeper::Application.where("owner_id IS NULL").find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def application_params
    params.require(:doorkeeper_application).permit(:name, :redirect_uri, :trusted, :scopes)
  end
end
