class DeployKeysController < ApplicationController
  respond_to :html
  layout "project"
  before_filter :project

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_admin_project!

  def project
    @project ||= Project.find_by_code(params[:project_id])
  end

  def index
    @keys = @project.deploy_keys.all
  end

  def show
    @key = @project.deploy_keys.find(params[:id])
  end

  def new
    @key = @project.deploy_keys.new

    respond_with(@key)
  end

  def create
    @key = @project.deploy_keys.new(params[:key])
    if @key.save
      redirect_to project_deploy_keys_path(@project)
    else
      render "new"
    end
  end

  def destroy
    @key = @project.deploy_keys.find(params[:id])
    @key.destroy

    respond_to do |format|
      format.html { redirect_to project_deploy_keys_url }
      format.js { render :nothing => true }
    end
  end
end
