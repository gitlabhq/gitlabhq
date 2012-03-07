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
    @hook.save

    if @hook.valid?
      redirect_to project_hook_path(@project, @hook)
    else
      render :new
    end
  end

  def test
    @hook = @project.web_hooks.find(params[:id])
    commits = @project.commits(@project.default_branch, nil, 3)
    data = @project.web_hook_data(commits.last.id, commits.first.id, "refs/heads/#{@project.default_branch}", current_user.keys.first.identifier)
    @hook.execute(data)

    redirect_to :back
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
