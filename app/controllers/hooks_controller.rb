class HooksController < ProjectResourceController
  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_admin_project!, only: [:new, :create, :destroy]

  respond_to :html

  def index
    @hooks = @project.hooks.all
    @hook = ProjectHook.new
  end

  def create
    @hook = @project.hooks.new(params[:hook])
    @hook.save

    if @hook.valid?
      redirect_to project_hooks_path(@project)
    else
      @hooks = @project.hooks.all
      render :index
    end
  end

  def test
    TestHookContext.new(project, current_user, params).execute

    redirect_to :back
  end

  def destroy
    @hook = @project.hooks.find(params[:id])
    @hook.destroy

    redirect_to project_hooks_path(@project)
  end
end
