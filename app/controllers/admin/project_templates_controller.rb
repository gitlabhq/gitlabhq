class Admin::ProjectTemplatesController < Admin::ApplicationController

  respond_to :html, :json, :js

  #layout 'navless', only: [:new, :create]
  before_filter :set_title, only: [:new, :create]

  def index
    @project_templates = ProjectTemplate.all
    @project_templates = @project_templates.order("project_templates.name ASC").page(params[:page]).per(20)
  end

  def show
    @project_template = ProjectTemplate.find_by_id(params[:id])
  end

  def new
    @project_template = ProjectTemplate.new
  end

  def create
    @project_template = ProjectTemplate.new(params[:project_template])
    @project_template.save_name = @project_template.name.dup.parameterize;

    respond_with(@project_template) do |format|
      if @project_template.save
        format.html { redirect_to admin_project_template_path(@project_template), notice: 'Project Template was successfully created.' }
      else
        format.html { render action: "new" }
      end
    end
  end

  def destroy
    @project_template = ProjectTemplate.find_by_id(params[:id])

    if @project_template.state == 0
      return
    end

    if ProjectTemplateWorker.perform_async(@project_template.id, true)
      @project_template.state = 3
      @project_template.save(:validate => false)

      redirect_to admin_project_templates_path, notice: 'Project Template will be deleted.'
    else
      render 'destroy', notice: 'Project Template could not be deleted successfully.'
    end
  end

  def set_title
    @title = 'New Project Template'
  end

end
