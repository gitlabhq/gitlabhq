class HooksController < ApplicationController
  before_filter :authenticate_user!
  before_filter :project
  layout "project"

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_read_project!
  before_filter :authorize_admin_project!, :only => [:new, :create, :destroy]

  respond_to :html

  def index
    @hooks = @project.web_hooks
  end

  def new
    @hook = @project.web_hooks.new
  end

  def create
    @hook = @project.web_hooks.new(params[:hook])
    @hook.author = current_user
    @hook.save

    if @hook.valid?
      redirect_to [@project, @hook]
    else
      respond_with(@hook)
    end
  end

  def show
    @hook = @project.web_hooks.find(params[:id])
  end

  def destroy
    @hook = @project.web_hooks.find(params[:id])
    @hook.destroy

    redirect_to project_hooks_path(@project)
  end
end
