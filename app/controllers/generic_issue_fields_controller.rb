class GenericIssueFieldsController < ProjectResourceController
  before_filter :module_enabled
  before_filter :authorize_admin_generic_issue_fields!
  before_filter :generic_issue_field, only: [:edit, :update, :destroy, :show]
  respond_to :html

  def index
    @generic_issue_fields = @project.generic_issue_fields
  end

  def new
    @generic_issue_field = @project.generic_issue_fields.new
    respond_with(@generic_issue_field)
  end

  def edit
    respond_with(@generic_issue_field)
  end

  def create
    @generic_issue_field = @project.generic_issue_fields.new(params[:generic_issue_field])

    if @generic_issue_field.save
      redirect_to project_generic_issue_fields_path(@project)
    else
      render :new
    end
  end

  def show
    redirect_to project_generic_issue_fields_path(@project)
  end

  def update
    @generic_issue_field.update_attributes(params[:generic_issue_field])

    if @generic_issue_field.valid?
      redirect_to project_generic_issue_fields_path(@project)
    else
      render :edit
    end
  end

  def destroy
    @generic_issue_field.destroy
    redirect_to project_generic_issue_fields_path(@project)
  end

  protected

  def generic_issue_field
    @generic_issue_field ||= @project.generic_issue_fields.find(params[:id])
  end

  def authorize_admin_generic_issue_fields!
    return access_denied! unless can?(current_user, :admin_generic_issue_fields, @project)
  end

  def module_enabled
    return render_404 unless @project.issues_enabled
  end
end
