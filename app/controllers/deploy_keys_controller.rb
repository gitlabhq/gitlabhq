class DeployKeysController < ApplicationController
  respond_to :js
  layout "project"
  before_filter :project

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_admin_project!

  def project
    @project ||= Project.find_by_code(params[:project_id])
  end

  def index
    @keys = @project.keys.all
  end

  def show
    @key = @project.keys.find(params[:id])
  end

  def new
    @key = @project.keys.new

    respond_with(@key)
  end

  def create
    @key = @project.keys.new(params[:key])
    @key.save

    respond_with(@key)
  end

  def destroy
    @key = @project.keys.find(params[:id])
    @key.destroy

    respond_to do |format|
      format.html { redirect_to project_deploy_keys_url }
      format.js { render :nothing => true }
    end
  end
end
