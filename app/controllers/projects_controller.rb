class ProjectsController < ApplicationController
  include ExtractsPath

  skip_before_action :authenticate_user!, only: [:show, :activity]
  before_action :project, except: [:new, :create]
  before_action :repository, except: [:new, :create]
  before_action :assign_ref_vars, :tree, only: [:show], if: :repo_exists?

  # Authorize
  before_action :authorize_admin_project!, only: [:edit, :update, :housekeeping]
  before_action :event_filter, only: [:show, :activity]

  layout :determine_layout

  def index
    redirect_to(current_user ? root_path : explore_root_path)
  end

  def new
    @project = Project.new
  end

  def edit
    render 'edit'
  end

  def create
    @project = ::Projects::CreateService.new(current_user, project_params).execute

    if @project.saved?
      redirect_to(
        project_path(@project),
        notice: "Project '#{@project.name}' was successfully created."
      )
    else
      render 'new'
    end
  end

  def update
    status = ::Projects::UpdateService.new(@project, current_user, project_params).execute

    respond_to do |format|
      if status
        flash[:notice] = "Project '#{@project.name}' was successfully updated."
        format.html do
          redirect_to(
            edit_project_path(@project),
            notice: "Project '#{@project.name}' was successfully updated."
          )
        end
        format.js
      else
        format.html { render 'edit' }
        format.js
      end
    end
  end

  def transfer
    return access_denied! unless can?(current_user, :change_namespace, @project)

    namespace = Namespace.find_by(id: params[:new_namespace_id])
    ::Projects::TransferService.new(project, current_user).execute(namespace)

    if @project.errors[:new_namespace].present?
      flash[:alert] = @project.errors[:new_namespace].first
    end
  end

  def remove_fork
    return access_denied! unless can?(current_user, :remove_fork_project, @project)

    if @project.unlink_fork
      flash[:notice] = 'The fork relationship has been removed.'
    end
  end

  def activity
    respond_to do |format|
      format.html
      format.json do
        load_events
        pager_json('events/_events', @events.count)
      end
    end
  end

  def show
    if @project.import_in_progress?
      redirect_to namespace_project_import_path(@project.namespace, @project)
      return
    end

    if @project.pending_delete?
      flash[:alert] = "Project queued for delete."
    end

    respond_to do |format|
      format.html do
        if @project.repository_exists?
          if @project.empty_repo?
            render 'projects/empty'
          else
            if current_user
              @membership = @project.team.find_member(current_user.id)
            end

            render :show
          end
        else
          render 'projects/no_repo'
        end
      end

      format.atom do
        load_events
        render layout: false
      end
    end
  end

  def destroy
    return access_denied! unless can?(current_user, :remove_project, @project)

    ::Projects::DestroyService.new(@project, current_user, {}).pending_delete!
    flash[:alert] = "Project '#{@project.name}' will be deleted."

    redirect_to dashboard_projects_path
  rescue Projects::DestroyService::DestroyError => ex
    redirect_to edit_project_path(@project), alert: ex.message
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

  def housekeeping
    ::Projects::HousekeepingService.new(@project).execute

    respond_to do |format|
      flash[:notice] = "Housekeeping successfully started."
      format.html { redirect_to project_path(@project) }
    end
  end

  def toggle_star
    current_user.toggle_star(@project)
    @project.reload

    render json: {
      star_count: @project.star_count
    }
  end

  def markdown_preview
    text = params[:text]

    ext = Gitlab::ReferenceExtractor.new(@project, current_user, current_user)
    ext.analyze(text)

    render json: {
      body:       view_context.markdown(text),
      references: {
        users: ext.users.map(&:username)
      }
    }
  end

  private

  def determine_layout
    if [:new, :create].include?(action_name.to_sym)
      'application'
    elsif [:edit, :update].include?(action_name.to_sym)
      'project_settings'
    else
      'project'
    end
  end

  def load_events
    @events = @project.events.recent
    @events = event_filter.apply_filter(@events).with_associations
    limit = (params[:limit] || 20).to_i
    @events = @events.limit(limit).offset(params[:offset] || 0)
  end

  def project_params
    params.require(:project).permit(
      :name, :path, :description, :issues_tracker, :tag_list, :runners_token,
      :issues_enabled, :merge_requests_enabled, :snippets_enabled, :issues_tracker_id, :default_branch,
      :wiki_enabled, :visibility_level, :import_url, :last_activity_at, :namespace_id, :avatar,
      :builds_enabled, :build_allow_git_fetch, :build_timeout_in_minutes, :build_coverage_regex,
      :public_builds,
    )
  end

  def autocomplete_emojis
    Rails.cache.fetch("autocomplete-emoji-#{Gemojione::VERSION}") do
      Emoji.emojis.map do |name, emoji|
        {
          name: name,
          path: view_context.image_url("#{emoji["unicode"]}.png")
        }
      end
    end
  end

  def repo_exists?
    project.repository_exists? && !project.empty_repo?
  end

  # Override get_id from ExtractsPath, which returns the branch and file path
  # for the blob/tree, which in this case is just the root of the default branch.
  def get_id
    project.repository.root_ref
  end
end
