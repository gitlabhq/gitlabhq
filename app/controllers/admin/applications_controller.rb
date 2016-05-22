#encoding: utf-8
class Admin::ApplicationsController < Admin::ApplicationController
  before_action :set_application, only: [:show, :edit, :update, :destroy]

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
    @application = Doorkeeper::Application.new(application_params)

    if @application.save
      flash[:notice] = I18n.t(:notice, scope: [:doorkeeper, :flash, :applications, :create])
      redirect_to admin_application_url(@application)
    else
      render :new
    end
  end

  def update
    if @application.update(application_params)
      redirect_to admin_application_path(@application), notice: '应用更新成功。'
    else
      render :edit
    end
  end

  def destroy
    @application.destroy
    redirect_to admin_applications_url, notice: '应用销毁成功。'
  end

  private

  def set_application
    @application = Doorkeeper::Application.where("owner_id IS NULL").find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def application_params
    params[:doorkeeper_application].permit(:name, :redirect_uri)
  end
end
