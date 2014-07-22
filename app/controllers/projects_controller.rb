class ProjectsController < ApplicationController
  skip_before_filter :authenticate_user!, only: [:show]
  before_filter :project, except: [:new, :create]
  before_filter :repository, except: [:new, :create]

  # Authorize
  before_filter :authorize_read_project!, except: [:index, :new, :create]
  before_filter :authorize_admin_project!, only: [:edit, :update, :destroy, :transfer, :archive, :unarchive, :retry_import]
  before_filter :require_non_empty_project, only: [:blob, :tree, :graph]

  layout 'navless', only: [:new, :create, :fork]
  before_filter :set_title, only: [:new, :create]

  def new
    @project = Project.new
  end

  def edit
    render 'edit', layout: "project_settings"
  end

  def create
    @project = ::Projects::CreateService.new(current_user, project_params).execute
    flash[:notice] = 'Project was successfully created.' if @project.saved?

    respond_to do |format|
      format.js
    end
  end

  def update
    status = ::Projects::UpdateService.new(@project, current_user, project_params).execute

    respond_to do |format|
      if status
        flash[:notice] = 'Project was successfully updated.'
        format.html { redirect_to edit_project_path(@project), notice: 'Project was successfully updated.' }
        format.js
      else
        format.html { render "edit", layout: "project_settings" }
        format.js
      end
    end
  end

  def transfer
    ::Projects::TransferService.new(project, current_user, project_params).execute
  end

  def show
    if @project.import_in_progress?
      redirect_to import_project_path(@project)
      return
    end

    return authenticate_user! unless @project.public? || current_user

    limit = (params[:limit] || 20).to_i
    @events = @project.events.recent
    @events = event_filter.apply_filter(@events)
    @events = @events.limit(limit).offset(params[:offset] || 0)

    respond_to do |format|
      format.html do
        if @project.empty_repo?
          render "projects/empty", layout: user_layout
        else
          @last_push = current_user.recent_push(@project.id) if current_user
          render :show, layout: user_layout
        end
      end
      format.json { pager_json("events/_events", @events.count) }
    end
  end

  def import
    if project.import_finished?
      redirect_to @project
      return
    end
  end

  def retry_import
    unless @project.import_failed?
      redirect_to import_project_path(@project)
    end

    @project.import_url = project_params[:import_url]

    if @project.save
      @project.reload
      @project.import_retry
    end

    redirect_to import_project_path(@project)
  end

  def destroy
    return access_denied! unless can?(current_user, :remove_project, project)

    ::Projects::DestroyService.new(@project, current_user, {}).execute

    respond_to do |format|
      format.html { redirect_to root_path }
    end
  end

  def fork
    @forked_project = ::Projects::ForkService.new(project, current_user).execute

    respond_to do |format|
      format.html do
        if @forked_project.saved? && @forked_project.forked?
          redirect_to(@forked_project, notice: 'Project was successfully forked.')
        else
          @title = 'Fork project'
          render "fork"
        end
      end
      format.js
    end
  end

  def autocomplete_sources
    note_type = params['type']
    note_id = params['type_id']
    participants = ::Projects::ParticipantsService.new(@project).execute(note_type, note_id)
    @suggestions = {
      emojis: Emoji.names.map { |e| { name: e, path: view_context.image_url("emoji/#{e}.png") } },
      issues: @project.issues.select([:iid, :title, :description]),
      mergerequests: @project.merge_requests.select([:iid, :title, :description]),
      members: participants
    }

    respond_to do |format|
      format.json { render :json => @suggestions }
    end
  end

  def archive
    return access_denied! unless can?(current_user, :archive_project, project)
    project.archive!

    respond_to do |format|
      format.html { redirect_to @project }
    end
  end

  def unarchive
    return access_denied! unless can?(current_user, :archive_project, project)
    project.unarchive!

    respond_to do |format|
      format.html { redirect_to @project }
    end
  end

  def upload_image
    link_to_image = ::Projects::ImageService.new(repository, params, root_url).execute

    respond_to do |format|
      if link_to_image
        format.json { render json: { link: link_to_image } }
      else
        format.json { render json: "Invalid file.", status: :unprocessable_entity }
      end
    end
  end

  private

  def upload_path
    base_dir = FileUploader.generate_dir
    File.join(repository.path_with_namespace, base_dir)
  end

  def accepted_images
    %w(png jpg jpeg gif)
  end

  def set_title
    @title = 'New Project'
  end

  def user_layout
    current_user ? "projects" : "public_projects"
  end

  def project_params
    params.require(:project).permit(
      :name, :path, :description, :issues_tracker, :label_list,
      :issues_enabled, :merge_requests_enabled, :snippets_enabled, :issues_tracker_id, :default_branch,
      :wiki_enabled, :visibility_level, :import_url, :last_activity_at, :namespace_id
    )
  end
end
