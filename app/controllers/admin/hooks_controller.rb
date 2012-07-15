class Admin::HooksController < ApplicationController
  layout "admin"
  before_filter :authenticate_user!
  before_filter :authenticate_admin!
  
  def index
    @hooks = SystemHook.all
    @hook = SystemHook.new
  end

  def create
    @hook = SystemHook.new(params[:hook])

    if @hook.save
      redirect_to admin_hooks_path, notice: 'Hook was successfully created.'
    else
      @hooks = SystemHook.all
      render :index 
    end
  end

  def destroy
    @hook = SystemHook.find(params[:id])
    @hook.destroy

    redirect_to admin_hooks_path
  end


  def test
    @hook = @project.hooks.find(params[:id])
    commits = @project.commits(@project.default_branch, nil, 3)
    data = @project.post_receive_data(commits.last.id, commits.first.id, "refs/heads/#{@project.default_branch}", current_user)
    @hook.execute(data)

    redirect_to :back
  end
end
