class Projects::EnvironmentsController < Projects::ApplicationController
  layout 'project'
  before_action :authorize_read_environment!
  before_action :authorize_create_environment!, only: [:new, :create]
  before_action :authorize_create_deployment!, only: [:stop]
  before_action :authorize_update_environment!, only: [:edit, :update]
  before_action :environment, only: [:show, :edit, :update, :stop]

  def index
    @scope = params[:scope]
    @all_environments = project.environments
    @environments =
      if @scope == 'stopped'
        @all_environments.stopped
      else
        @all_environments.available
      end
    
    respond_to do |format|
      format.html
      format.json do
        render json: serialize_as_json(@environments)
      end
    end
  end

  def show
    @deployments = environment.deployments.order(id: :desc).page(params[:page])
  end

  def new
    @environment = project.environments.new
  end

  def edit
  end

  def create
    @environment = project.environments.create(environment_params)

    if @environment.persisted?
      redirect_to namespace_project_environment_path(project.namespace, project, @environment)
    else
      render :new
    end
  end

  def update
    if @environment.update(environment_params)
      redirect_to namespace_project_environment_path(project.namespace, project, @environment)
    else
      render :edit
    end
  end

  def stop
    return render_404 unless @environment.stoppable?

    new_action = @environment.stop!(current_user)
    redirect_to polymorphic_path([project.namespace.becomes(Namespace), project, new_action])
  end

  private

  def environment_params
    params.require(:environment).permit(:name, :external_url)
  end

  def environment
    @environment ||= project.environments.find(params[:id])
  end
  
  def serialize_as_json(resource)
    resource.as_json(
      include: {
        last_deployment: {
          include: {
            user: { only: [:id, :name, :username], methods: [:avatar_url] },
            deployable: { only: [:id, :name, :ref, :tag] }
          },
          methods: [:short_sha, :commit_title, :commit]
        },
        project: { methods: [:namespace] }
      }
    )
  end
end
