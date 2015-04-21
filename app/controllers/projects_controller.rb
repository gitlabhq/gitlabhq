class ProjectsController < ApplicationController
  prepend_before_filter :render_go_import, only: [:show]
  skip_before_action :authenticate_user!, only: [:show]
  before_action :project, except: [:new, :create]
  before_action :repository, except: [:new, :create]

  # Authorize
  before_action :authorize_admin_project!, only: [:edit, :update, :destroy, :transfer, :archive, :unarchive]
  before_action :set_title, only: [:new, :create]
  before_action :event_filter, only: :show

  layout 'navless', only: [:new, :create, :fork]

  def new
    @project = Project.new
  end

  def edit
    render 'edit', layout: 'project_settings'
  end

  def create
    @project = ::Projects::CreateService.new(current_user, project_params).execute

    if @project.saved?
      redirect_to(
        project_path(@project),
        notice: 'Project was successfully created.'
      )
    else
      render 'new'
    end
  end

  def update
    status = ::Projects::UpdateService.new(@project, current_user, project_params).execute

    respond_to do |format|
      if status
        flash[:notice] = 'Project was successfully updated.'
        format.html do
          redirect_to(
            edit_project_path(@project),
            notice: 'Project was successfully updated.'
          )
        end
        format.js
      else
        format.html { render 'edit', layout: 'project_settings' }
        format.js
      end
    end
  end

  def transfer
    transfer_params = params.permit(:new_namespace_id)
    ::Projects::TransferService.new(project, current_user, transfer_params).execute
    if @project.errors[:namespace_id].present?
      flash[:alert] = @project.errors[:namespace_id].first
    end
  end

  def show
    if @project.import_in_progress?
      redirect_to namespace_project_import_path(@project.namespace, @project)
      return
    end

    @show_star = !(current_user && current_user.starred?(@project))

    respond_to do |format|
      format.html do
        if @project.repository_exists?
          if @project.empty_repo?
            render 'projects/empty', layout: user_layout
          else
            @last_push = current_user.recent_push(@project.id) if current_user
            render :show, layout: user_layout
          end
        else
          render 'projects/no_repo', layout: user_layout
        end
      end

      format.json do
        load_events
        pager_json('events/_events', @events.count)
      end

      format.atom do
        load_events
        render layout: false
      end
    end
  end

  def destroy
    return access_denied! unless can?(current_user, :remove_project, @project)

    ::Projects::DestroyService.new(@project, current_user, {}).execute

    respond_to do |format|
      format.html do
        flash[:alert] = 'Project deleted.'

        if request.referer.include?('/admin')
          redirect_to admin_namespaces_projects_path
        else
          redirect_to dashboard_path
        end
      end
    end
  end

  def autocomplete_sources
    note_type = params['type']
    note_id = params['type_id']
    autocomplete = ::Projects::AutocompleteService.new(@project)
    participants = ::Projects::ParticipantsService.new(@project, current_user).execute(note_type, note_id)

    @suggestions = {
      emojis: autocomplete_emojis,
      issues: autocomplete.issues,
      mergerequests: autocomplete.merge_requests,
      members: participants
    }

    respond_to do |format|
      format.json { render json: @suggestions }
    end
  end

  def archive
    return access_denied! unless can?(current_user, :archive_project, @project)
    @project.archive!

    respond_to do |format|
      format.html { redirect_to project_path(@project) }
    end
  end

  def unarchive
    return access_denied! unless can?(current_user, :archive_project, @project)
    @project.unarchive!

    respond_to do |format|
      format.html { redirect_to project_path(@project) }
    end
  end

  def toggle_star
    current_user.toggle_star(@project)
    @project.reload
    render json: { star_count: @project.star_count }
  end

  def markdown_preview
    render text: view_context.markdown(params[:md_text])
  end

  private

  def set_title
    @title = 'New Project'
  end

  def user_layout
    current_user ? 'projects' : 'public_projects'
  end

  def load_events
    @events = @project.events.recent
    @events = event_filter.apply_filter(@events).with_associations
    limit = (params[:limit] || 20).to_i
    @events = @events.limit(limit).offset(params[:offset] || 0)
  end

  def project_params
    params.require(:project).permit(
      :name, :path, :description, :issues_tracker, :tag_list,
      :issues_enabled, :merge_requests_enabled, :snippets_enabled, :issues_tracker_id, :default_branch,
      :wiki_enabled, :visibility_level, :import_url, :last_activity_at, :namespace_id, :avatar
    )
  end

  def autocomplete_emojis
    Rails.cache.fetch("autocomplete-emoji-#{Gemojione::VERSION}") do
      Emoji.emojis.map do |name, emoji|
        {
          name: name,
          path: view_context.image_url("emoji/#{emoji["unicode"]}.png")
        }
      end
    end
  end

  def render_go_import
    return unless params["go-get"] == "1"

    @namespace = params[:namespace_id]
    @id = params[:project_id] || params[:id]
    @id = @id.gsub(/\.git\Z/, "")

    render "go_import", layout: false
  end
end
